import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter/rendering.dart';
import 'package:passtime/menu/request_refund.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final Dio _dio = Dio();
  Map<String, dynamic>? ticketData;
  bool isLoading = true;
  bool hasError = false;

  // 1. GlobalKey와 점선의 Y 좌표를 저장할 변수 추가
  final GlobalKey _dottedLineKey = GlobalKey();
  double _dottedLineY = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTicketDetail();

    // 3. 화면 렌더링이 끝난 후 점선의 위치를 계산하는 함수 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCirclePosition();
    });
  }

  Future<void> fetchTicketDetail() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/detail';
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: {'ticketId': widget.ticketId},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data['isSuccess'] == true) {
        setState(() {
          ticketData = response.data['result'];
          isLoading = false;
        });
        // 데이터 로드 후에도 위치를 다시 계산하도록 설정
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _updateCirclePosition());
      } else {
        throw Exception('Failed to load ticket details');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // 4. 점선의 위치를 계산하고 상태를 업데이트하는 함수
  void _updateCirclePosition() {
    final RenderBox? box =
        _dottedLineKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      // Column 내부에서의 상대적인 Y 좌표를 가져옵니다.
      final parentData = box.parentData as FlexParentData;
      final yPosition = parentData.offset.dy;

      // 계산된 위치가 현재 위치와 다를 경우에만 UI를 갱신합니다.
      // 반원의 높이가 30이므로, Y축 중심을 맞추기 위해 15를 빼줍니다.
      if (yPosition > 0 && _dottedLineY != yPosition - 15) {
        setState(() {
          _dottedLineY = yPosition - 15;
        });
      }
    }
  }

  Widget _buildKakaoMap() {
    final kakaoPlace = ticketData?['kakaoPlace'] as Map<String, dynamic>?;

    if (kakaoPlace == null ||
        kakaoPlace['y'] == null ||
        kakaoPlace['x'] == null) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: Text(
            "지도 정보를 불러올 수 없습니다.",
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }

    try {
      final double lat = double.parse(kakaoPlace['y']);
      final double lng = double.parse(kakaoPlace['x']);
      final LatLng position = LatLng(latitude: lat, longitude: lng);

      return KakaoMap(
        initialPosition: position,
        initialLevel: 17,
      );
    } catch (e) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: Text(
            "잘못된 지도 정보입니다.",
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // build가 호출될 때마다 위치를 다시 계산하도록 예약합니다.
    // 이렇게 하면 화면 크기 변경 등에도 대응할 수 있습니다.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateCirclePosition());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF334D61),
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '입장권',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError || ticketData == null
              ? Align(
                  alignment: const Alignment(0.0, -0.15),
                  child: Text(
                    '입장권 유효기간이 만료되었습니다',
                    style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF334D61).withOpacity(0.5),
                        fontWeight: FontWeight.bold),
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(40),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // 상단 정보 영역
                                  Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "입장권",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          ticketData?["eventTitle"] ??
                                              "행사 제목 없음",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Divider(
                                            height: 30,
                                            thickness: 1,
                                            color: Color(0xFFEEEDE3)),
                                        // 날짜/시간
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "날짜",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    ticketData?["eventDay"] ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const SizedBox(
                                              height: 30,
                                              child: VerticalDivider(
                                                color: Color(0xFFEEEDE3),
                                                thickness: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "시간",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    ticketData?[
                                                            "eventStartTime"] ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(
                                            height: 30,
                                            thickness: 1,
                                            color: Color(0xFFEEEDE3)),
                                        Text(
                                            ticketData?["eventComment"] ??
                                                "관리자 멘트 없음",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        const Divider(
                                            height: 30,
                                            thickness: 1,
                                            color: Color(0xFFEEEDE3)),
                                        // 장소 설명
                                        Text(
                                          "장소 설명",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 5),
                                        Container(
                                          height:
                                              82, // 1. 전체 공간의 높이를 60으로 고정합니다.
                                          alignment: Alignment
                                              .topLeft, // 2. 자식 위젯(Text)을 컨테이너의 왼쪽 상단에 배치합니다.
                                          child: Text(
                                            ticketData?["eventPlaceComment"] ??
                                                "장소 설명 없음",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        // 취소/환불 버튼
                                        TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const RequestRefundScreen()),
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF334D61)
                                                    .withOpacity(0.05),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            minimumSize:
                                                const Size(double.infinity, 0),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "취소/환불요청",
                                              style: TextStyle(
                                                  color: Color(0xFF334D61),
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 점선 구분선
                                  SizedBox(
                                    key: _dottedLineKey, // 2. 점선 위젯에 key 할당
                                    height: 0,
                                    child: CustomPaint(
                                      painter: DottedLinePainter(),
                                      child: Container(),
                                    ),
                                  ),
                                  // 2. 지도 + Marquee 영역 (Stack으로 변경)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    child: Stack(
                                      children: [
                                        // 지도 (배경)
                                        SizedBox(
                                          height: 200,
                                          width: double.infinity,
                                          child: IgnorePointer(
                                            ignoring: true,
                                            child: _buildKakaoMap(),
                                          ),
                                        ),
                                        // Marquee (지도 위에 겹쳐짐)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            width: double.infinity,
                                            height: 23,
                                            color: const Color(0xFFC10230),
                                            child: Marquee(
                                              text: "캡쳐하신 입장권은 사용할 수 없습니다.",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              scrollAxis: Axis.horizontal,
                                              blankSpace: 50.0,
                                              velocity: 50.0,
                                            ),
                                          ),
                                        ),
                                        // 여기에 이미지 추가
                                        Positioned(
                                          top: 65, // Stack 상단에서 20픽셀 아래에 위치
                                          left: 0,
                                          right: 0,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Image.asset(
                                              'assets/images/marker.png', // 사용할 이미지 경로
                                              width: 40, // 이미지 너비
                                              height: 40, // 이미지 높이
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // 좌우의 반원 (점선 위치에 맞춰 조정)
                              // 5. top 값을 고정값 대신 동적으로 계산된 _dottedLineY 변수로 변경
                              if (_dottedLineY > 0)
                                Positioned(
                                  left: -15,
                                  top: _dottedLineY,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5F6F7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (_dottedLineY > 0)
                                Positioned(
                                  right: -15,
                                  top: _dottedLineY,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5F6F7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// 점선 그리는 CustomPainter
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 5;
    const double dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
