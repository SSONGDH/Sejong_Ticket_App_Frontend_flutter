import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:marquee/marquee.dart';

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
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "입장권",
        backgroundColor: Color(0xFFB93234),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : hasError || ticketData == null
              ? const Center(child: Text("입장권 정보를 불러올 수 없습니다."))
              : Stack(
                  children: [
                    // 🔴 빨간색 도형
                    Positioned(
                      top: 280,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB93234),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 220),

                            // 취소/환불 요청 버튼
                            TextButton(
                              onPressed: () {
                                // TODO: 환불 요청 화면으로 이동
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF8F8FF),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 118),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                              child: const Text(
                                "취소/환불 요청",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ✅ 캡처 방지 안내 문구
                            Container(
                              width: double.infinity,
                              height: 30,
                              margin: EdgeInsets.zero,
                              padding: EdgeInsets.zero,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF889),
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                              ),
                              child: Marquee(
                                text: "캡쳐하신 입장권은 사용할 수 없습니다   ",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                scrollAxis: Axis.horizontal,
                                blankSpace: 50.0,
                                velocity: 50.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ⚪ 회색 카드
                    Positioned(
                      top: 80,
                      left: 36,
                      right: 36,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F8FF),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            // 이벤트 제목
                            Text(
                              ticketData?["eventTitle"] ?? "이벤트 제목 없음",
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${ticketData?["eventDay"] ?? ""} / ${ticketData?["eventStartTime"] ?? ""}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 25),

                            // 관리자 멘트
                            Text(
                              ticketData?["eventComment"] ?? "없음",
                              style: const TextStyle(color: Color(0xFFC1C1C1)),
                            ),
                            const SizedBox(height: 25),

                            // 사진 부분
                            ticketData?["eventPlacePicture"] != null
                                ? Container(
                                    height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.network(
                                      ticketData?["eventPlacePicture"] ?? "",
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          print("Image loaded successfully.");
                                          return child;
                                        } else {
                                          print("Image loading...");
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      (loadingProgress
                                                              .expectedTotalBytes ??
                                                          1)
                                                  : null,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  )
                                : const Text(
                                    "사진을 불러올 수 없습니다.",
                                    style: TextStyle(color: Colors.red),
                                  ),

                            const SizedBox(height: 10),

                            // 장소 설명
                            Container(
                              height: 70,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  ticketData?["eventPlaceComment"] ??
                                      "설명이 없습니다.",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
