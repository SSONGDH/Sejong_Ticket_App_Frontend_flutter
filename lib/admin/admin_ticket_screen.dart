import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/admin/ticket_edit.dart';
import 'package:passtime/admin/ticket_produce.dart';
import 'package:passtime/admin/request_refund_list.dart';
import 'package:passtime/admin/send_payment_list.dart';

class AdminTicketScreen extends StatelessWidget {
  const AdminTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tickets = [
      {
        'title': '컴공OT 뒤풀이',
        'dateTime': '2025.02.28(금) / 18:00',
        'location': '지그재그',
        'status': '사용가능',
        'statusColor': const Color(0xFF6035FB),
      },
      {
        'title': '행사 제목',
        'dateTime': '2025.03.01(토) / 19:00',
        'location': '서울역',
        'status': '환불중',
        'statusColor': const Color(0xFFDE4244),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "행사 관리", backgroundColor: Color(0xFF282727)),
      body: tickets.isEmpty
          ? const Center(
              child: Text(
                '현재 발급된 입장권이 없습니다',
                style: TextStyle(fontSize: 22, color: Color(0xFFC1C1C1)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TicketEditScreen()),
                    ),
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
                                ticket['title']!,
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
                                    backgroundColor: ticket['statusColor'],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    ticket['status']!,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("시간  ${ticket['dateTime']}",
                              style: const TextStyle(fontSize: 14)),
                          Text("장소  ${ticket['location']}",
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('행사 제작'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TicketProduceScreen())),
                  ),
                  ListTile(
                    title: const Text('환불 신청 목록'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RequestRefundListScreen())),
                  ),
                  ListTile(
                    title: const Text('납부 내역 목록'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SendPaymentListScreen())),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFF282727),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
