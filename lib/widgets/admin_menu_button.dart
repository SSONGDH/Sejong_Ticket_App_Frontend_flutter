import 'package:flutter/material.dart';
import 'package:passtime/admin/admin_ticket_screen.dart';
import 'package:passtime/admin/ticket_produce.dart';
import 'package:passtime/admin/send_payment_list.dart';
import 'package:passtime/admin/request_refund_list.dart';
import 'package:passtime/screens/ticket_screen.dart';

class AdminMenuButton extends StatefulWidget {
  const AdminMenuButton({super.key});

  @override
  State<AdminMenuButton> createState() => _AdminMenuButtonState();
}

class _AdminMenuButtonState extends State<AdminMenuButton> {
  bool _isMenuOpen = false;

  // 메뉴 항목을 구성하는 헬퍼 위젯
  Widget _buildMenuItem(BuildContext context,
      {required String imagePath,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 24,
              height: 24,
              color: const Color(0xFF7E929F),
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 버튼 근처(우측 하단)에 앵커되는 팝업 메뉴
  Future<void> _showAnchoredMenu(
      BuildContext context, List<Widget> items) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return Stack(
          children: [
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 84,
              child: FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  alignment: Alignment.bottomRight,
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _mainMenuItems(BuildContext context) {
    return [
      _buildMenuItem(
        context,
        imagePath: 'assets/images/calendar.png',
        text: '행사 관리',
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminTicketScreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/calendar-plus.png',
        text: '행사 제작',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TicketProduceScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/coins-stacked.png',
        text: '납부 내역 목록',
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SendPaymentListScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/coins-out.png',
        text: '환불 신청 목록',
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RequestRefundListScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/users.png',
        text: '참가자 모드',
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TicketScreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (_isMenuOpen) return;
        setState(() {
          _isMenuOpen = true;
        });
        _showAnchoredMenu(context, _mainMenuItems(context)).then((_) {
          if (mounted) {
            setState(() {
              _isMenuOpen = false;
            });
          }
        });
      },
      backgroundColor: const Color(0xFF334D61),
      shape: const CircleBorder(),
      child: Icon(
        _isMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}
