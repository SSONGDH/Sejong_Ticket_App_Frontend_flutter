import 'package:flutter/material.dart';
import 'package:PASSTIME/screens/ticket_detail_screen.dart';
import 'package:PASSTIME/screens/refund_screen.dart';

class TicketCard extends StatelessWidget {
  final String ticketId;
  final String title;
  final String dateTime;
  final String location;
  final String status;
  final Color statusColor;
  final Color appBarColor;

  const TicketCard({
    super.key,
    required this.ticketId,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.status,
    required this.statusColor,
    required this.appBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (status == '환불중' || status == '환불됨') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RefundScreen(ticketId: ticketId),
            ),
          );
        } else if (status == '미승인') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("알림"),
              content: const Text("아직 승인되지 않았습니다."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("확인"),
                ),
              ],
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: ticketId),
            ),
          );
        }
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
