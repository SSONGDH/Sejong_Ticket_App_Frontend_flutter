import 'package:flutter/material.dart';
import 'package:passtime/screens/ticket_detail_screen.dart';
import 'package:passtime/screens/refund_screen.dart';
import 'package:passtime/widgets/accent_event_card_shell.dart';

class TicketCard extends StatelessWidget {
  final String ticketId;
  final String title;
  final String dateTime;
  final String location;
  final String affiliation;
  final String status;
  final Color statusColor;

  const TicketCard({
    super.key,
    required this.ticketId,
    required this.title,
    required this.dateTime,
    required this.location,
    this.affiliation = '',
    required this.status,
    required this.statusColor,
  });

  bool get _isClickable => status != '사용 불가';

  Color get _accentColor =>
      status == '사용 가능' ? const Color(0xFFC10230) : statusColor;

  void _handleTap(BuildContext context) {
    if (!_isClickable) return;

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
          title: const Text('알림'),
          content: const Text('아직 승인되지 않았습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isClickable ? 1.0 : 0.65,
      child: AccentEventCardShell(
        accentColor: _accentColor,
        onTap: _isClickable ? () => _handleTap(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                        color: Color(0xFF334D61),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBox(),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '시간    ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: dateTime,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '장소    ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: location,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '주최 소속  ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: affiliation.isNotEmpty ? affiliation : '-',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBox() {
    return Container(
      width: 57,
      height: 24,
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
