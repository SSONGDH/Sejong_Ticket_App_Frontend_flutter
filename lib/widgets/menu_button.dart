import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:passtime/screens/ticket_screen.dart';
import 'package:passtime/menu/add_ticket_code.dart';
import 'package:passtime/menu/add_ticket_nfc.dart';
import 'package:passtime/menu/send_payment.dart';
import 'package:passtime/menu/request_refund.dart';
import 'package:passtime/menu/my_page_screen.dart';
import 'package:passtime/menu/settings.dart';
import 'package:passtime/utils/organizer_mode_navigation.dart';

class MenuButton extends StatefulWidget {
  const MenuButton({super.key});

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  final Dio dio = Dio();
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);
        options.headers['Cookie'] = cookies.isNotEmpty
            ? cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ')
            : '';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final responseCookies = response.headers['set-cookie'];
        if (responseCookies != null && responseCookies.isNotEmpty) {
          final parsedCookies = responseCookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();
          CookieJarSingleton().cookieJar.saveFromResponse(uri, parsedCookies);
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // 메뉴 항목을 구성하는 헬퍼 위젯
  Widget _buildMenuItem(BuildContext context,
      {required String imagePath,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // 메뉴 팝업 닫기
        onTap(); // 실제 동작 수행
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
        imagePath: 'assets/images/ticket.png',
        text: '입장권',
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TicketScreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/ticket-plus.png',
        text: '입장권 추가',
        onTap: () {
          _showAnchoredMenu(context, _addTicketItems(context));
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/coins-stacked.png',
        text: '납부 내역 보내기',
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const SendPaymentScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/coins-out.png',
        text: '환불 신청',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestRefundScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/user.png',
        text: '마이페이지',
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MyPageScreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/user-check.png',
        text: '주최자 모드',
        onTap: () {
          navigateToOrganizerMode(context, dio);
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/settings.png',
        text: '설정',
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    ];
  }

  List<Widget> _addTicketItems(BuildContext context) {
    return [
      _buildMenuItem(
        context,
        imagePath: 'assets/images/ticket-plus.png',
        text: 'CODE로 추가',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTicketCodeScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        imagePath: 'assets/images/ticket-plus.png',
        text: 'NFC로 추가',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTicketNfcScreen()),
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
      backgroundColor: const Color(0xFFC10230),
      shape: const CircleBorder(),
      child: Icon(
        _isMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}
