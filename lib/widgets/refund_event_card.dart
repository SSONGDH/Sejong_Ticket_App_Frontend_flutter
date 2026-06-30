import 'package:flutter/material.dart';
import 'package:passtime/widgets/accent_event_card_shell.dart';

class RefundEventCard extends StatelessWidget {
  final String title;
  final String dateTime;
  final String location;
  final int totalCount;
  final int pendingCount;
  final VoidCallback onTap;

  const RefundEventCard({
    super.key,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.totalCount,
    required this.pendingCount,
    required this.onTap,
  });

  static const _accentColor = Color(0xFFC10230);

  @override
  Widget build(BuildContext context) {
    return AccentEventCardShell(
      accentColor: _accentColor,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF334D61),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRefundBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$dateTime · $location',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.45),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '신청자 $totalCount명',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        TextSpan(
                          text: ' · ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        TextSpan(
                          text: '승인 대기 $pendingCount명',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: pendingCount > 0
                                ? const Color(0xFFC10230)
                                : Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.black.withOpacity(0.35),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '환불 목록',
        style: TextStyle(
          color: _accentColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
