import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:marquee/marquee.dart';
import 'package:PASSTIME/menu/request_refund.dart';

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

  @override
  void initState() {
    super.initState();
    fetchTicketDetail();
  }

  Future<void> fetchTicketDetail() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/detail';
    setState(() {
      isLoading = true; // 로딩 상태로 설정
    });

    try {
      print("Fetching ticket details..."); // 로딩 시작 로그
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
          isLoading = false; // 데이터를 성공적으로 받아오면 로딩 상태 해제
          print("Ticket details fetched successfully.");
          print("Ticket data: $ticketData");
        });
      } else {
        throw Exception('Failed to load ticket details');
      }
    } catch (e) {
      print("Error fetching ticket details: $e");
      setState(() {
        hasError = true;
        isLoading = false; // 오류 발생 시 로딩 상태 해제
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building the screen..."); // 화면 렌더링 로그

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
            size: 22,
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
              ? const Center(child: Text("입장권 유효기간이 만료되었습니다"))
              : SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // 티켓 모양의 카드
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // 상단 정보 영역
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "입장권",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          ticketData?["eventTitle"] ??
                                              "행사 제목 없음",
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text("날짜",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54)),
                                                Text(
                                                  ticketData?["eventDay"] ?? "",
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text("시간",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54)),
                                                Text(
                                                  ticketData?[
                                                          "eventStartTime"] ??
                                                      "",
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        const Text("관리자 멘트",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54)),
                                        Text(
                                          ticketData?["eventComment"] ??
                                              "관리자 멘트 없음",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text("장소 설명",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54)),
                                        Text(
                                          ticketData?["eventPlaceComment"] ??
                                              "장소 설명 없음",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 점선 구분선
                                  SizedBox(
                                    height: 30,
                                    child: CustomPaint(
                                      painter: DottedLinePainter(),
                                      child: Container(),
                                    ),
                                  ),
                                  // 하단 지도, 취소/환불 버튼, Marquee 영역
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 200,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "지도 표시 영역",
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const RequestRefundScreen()),
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.grey[100],
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "취소/환불 요청",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          width: double.infinity,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53935),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Marquee(
                                            text:
                                                "⚠️ 캡쳐하신 입장권은 사용할 수 없습니다 ⚠️   ",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            scrollAxis: Axis.horizontal,
                                            blankSpace: 50.0,
                                            velocity: 50.0,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // 좌우의 반원
                              Positioned(
                                left: -15,
                                top: 290, // 점선 위치에 맞춰 조정
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F6F7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -15,
                                top: 290, // 점선 위치에 맞춰 조정
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
