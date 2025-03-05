import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/ticket_card.dart';
// import 'package:passtime/admin/ticket_edit.dart';
import 'package:passtime/admin/ticket_produce.dart';
import 'package:passtime/admin/request_refund_list.dart';
import 'package:passtime/admin/send_payment_list.dart';

class AdminTicketScreen extends StatelessWidget {
  const AdminTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> tickets = [
      {
        'title': '컴공OT 뒤풀이',
        'dateTime': '2025.02.28(금) / 18:00',
        'location': '지그재그',
        'status': '사용가능',
        'statusColor': '0xFF444444',
      },
      {
        'title': '행사 제목',
        'dateTime': '2025.03.01(토) / 19:00',
        'location': '서울역',
        'status': '환불중',
        'statusColor': '0xFF444444',
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: tickets.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const SizedBox(height: 16);
                  }

                  final ticket = tickets[index - 1];
                  return TicketCard(
                    title: ticket['title']!,
                    dateTime: ticket['dateTime']!,
                    location: ticket['location']!,
                    status: ticket['status']!,
                    statusColor: Color(int.parse(ticket['statusColor']!)),
                    appBarColor: Color(int.parse(ticket['statusColor']!)),
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
