import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:marquee/marquee.dart';
import 'package:passtime/menu/request_refund.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          const CustomAppBar(title: "입장권", backgroundColor: Color(0xFFB93234)),
      body: Stack(
        children: [
          // 🔴 빨간색 도형 (회색 카드 뒤로 가도록 먼저 배치)
          Positioned(
            top: 280, // 회색 카드 아래 위치
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFB93234), // 빨간색
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 220),

                  // 취소/환불 요청 버튼
                  TextButton(
                    onPressed: () {
                      // Navigate to the RequestRefundScreen when the button is pressed
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RequestRefundScreen()),
                      );
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
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ 캡처 방지 안내 문구 (빨간색 도형과 정확히 붙도록 수정)
                  Container(
                    width: double.infinity,
                    height: 30, // 높이 설정
                    margin: EdgeInsets.zero, // ✅ 여백 제거
                    padding: EdgeInsets.zero, // ✅ 패딩 제거
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF889),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(8)), // 하단 모서리만 둥글게
                    ),
                    child: Marquee(
                      text: "캡쳐하신 입장권은 사용할 수 없습니다   ", // 공백 추가해서 자연스럽게 연결
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      scrollAxis: Axis.horizontal, // 가로로 이동
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: 50.0, // 문구 사이의 간격
                      velocity: 50.0, // 속도 조절
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ⚪ 회색 카드 (위에 올라가도록 배치)
          Positioned(
            top: 80, // 빨간색 영역을 넘어서 배치
            left: 36,
            right: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  const Text(
                    "행사 제목",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "2025.02.28(금) / 18:00",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "관리자 한마디",
                    style: TextStyle(color: Color(0xFFC1C1C1)),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.yellow[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text("장소 설명란",
                          style: TextStyle(color: Colors.black54)),
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
