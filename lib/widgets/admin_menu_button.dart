import 'package:flutter/material.dart';
import 'package:PASSTIME/admin/admin_ticket_screen.dart';
import 'package:PASSTIME/admin/ticket_produce.dart';
import 'package:PASSTIME/admin/send_payment_list.dart';
import 'package:PASSTIME/admin/request_refund_list.dart';
import 'package:PASSTIME/admin/request_admin_list.dart';
import 'package:PASSTIME/screens/ticket_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _isMenuOpen = !_isMenuOpen;
        });

        if (_isMenuOpen) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // '행사 관리' 메뉴
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/images/calendar.png', // 예시 이미지 경로
                        text: '행사 관리',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminTicketScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      // '행사 제작' 메뉴
                      _buildMenuItem(
                        context,
                        imagePath:
                            'assets/images/calendar-plus.png', // 예시 이미지 경로
                        text: '행사 제작',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TicketProduceScreen()),
                          );
                        },
                      ),
                      // '납부 내역 목록' 메뉴
                      _buildMenuItem(
                        context,
                        imagePath:
                            'assets/images/coins-stacked.png', // 예시 이미지 경로
                        text: '납부 내역 목록',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SendPaymentListScreen()),
                          );
                        },
                      ),
                      // '환불 신청 목록' 메뉴
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/images/coins-out.png', // 예시 이미지 경로
                        text: '환불 신청 목록',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RequestRefundListScreen()),
                          );
                        },
                      ),
                      // '주최자 신청 목록' 메뉴
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/images/user-check.png', // 예시 이미지 경로
                        text: '주최자 신청 목록',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RequestAdminListScreen()),
                          );
                        },
                      ),
                      // '참가자 모드' 메뉴
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/images/users.png', // 예시 이미지 경로
                        text: '참가자 모드',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TicketScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      )
                    ],
                  ),
                ),
              );
            },
          ).then((_) {
            if (mounted) {
              setState(() {
                _isMenuOpen = false;
              });
            }
          });
        }
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
