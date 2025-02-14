import 'package:flutter/material.dart';
import 'package:passtime/screens/ticket_detail_screen.dart';

class TicketCard extends StatelessWidget {
  final String title;
  final String dateTime;
  final String location;
  final String status;
  final Color statusColor;
  final Color appBarColor; // 추가: 앱바 색상 변수

  const TicketCard({
    super.key,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.status,
    required this.statusColor,
    required this.appBarColor, // 추가: 앱바 색상 전달
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // GestureDetector를 사용하여 탭 이벤트 추가
      onTap: () {
        // 카드가 클릭되면 ticket_detail_screen.dart로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TicketDetailScreen(
                // title: title, // 제목을 전달하여 상세 화면으로 이동
                // appBarColor: appBarColor, // 앱바 색상 전달
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 65,
                  height: 29,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("시간  $dateTime", style: const TextStyle(fontSize: 14)),
            Text("장소  $location", style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
