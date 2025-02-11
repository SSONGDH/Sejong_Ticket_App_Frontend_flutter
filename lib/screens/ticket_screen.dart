import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/ticket_card.dart';
import 'package:passtime/menu/send_payment.dart';
import 'package:passtime/menu/add_ticket.dart';
import 'package:passtime/menu/request_refund.dart';
import 'package:passtime/menu/settings.dart';
import 'package:passtime/menu/admin_mode.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> tickets = [
      {
        'title': '컴공OT 뒤풀이',
        'dateTime': '2025.02.28(금) / 18:00',
        'location': '지그재그',
        'status': '사용가능',
        'statusColor': '0xFF6035FB',
      },
      {
        'title': '행사 제목',
        'dateTime': '2025.03.01(토) / 19:00',
        'location': '서울역',
        'status': '환불중',
        'statusColor': '0xFFDE4244',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white, // ✅ 배경색 통일
      appBar: const CustomAppBar(
        title: "입장권",
        backgroundColor: Color(0xFFB93234),
      ),
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
            backgroundColor: Colors.white, // ✅ 배경색 고정
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('납부내역 보내기'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SendPaymentScreen())),
                  ),
                  ListTile(
                    title: const Text('입장권 추가'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddTicketScreen())),
                  ),
                  ListTile(
                    title: const Text('환불 신청'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RequestRefundScreen())),
                  ),
                  ListTile(
                    title: const Text('설정'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                  ListTile(
                    title: const Text('관리자 모드'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminModeScreen())),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFFB93234),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
