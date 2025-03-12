import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/admin/request_refund_detail_screen.dart';

class RequestRefundListScreen extends StatelessWidget {
  const RequestRefundListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> refundRequests = [
      {
        'title': '컴공OT 뒤풀이',
        'studentInfo': '24011184 / 윤재민',
        'visitTime': '2025.02.25(화) / 15:00',
        'status': '승인됨',
        'statusColor': const Color(0xFF6035FB),
      },
      {
        'title': '행사 제목',
        'studentInfo': '',
        'visitTime': '',
        'status': '미승인',
        'statusColor': const Color(0xFFDE4244),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "환불 신청 목록",
        backgroundColor: Color(0xFF282727),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.builder(
          itemCount: refundRequests.length,
          itemBuilder: (context, index) {
            final refund = refundRequests[index];
            return GestureDetector(
              onTap: () {
                // ✅ 티켓을 클릭하면 상세 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestRefundDetailScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          refund['title']!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: refund['statusColor'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            refund['status']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (refund['studentInfo']!.isNotEmpty)
                      Text("학생 정보  ${refund['studentInfo']}",
                          style: const TextStyle(fontSize: 14)),
                    if (refund['visitTime']!.isNotEmpty)
                      Text("방문 시간  ${refund['visitTime']}",
                          style: const TextStyle(fontSize: 14)),
                    const Text("환불 사유", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
