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
import 'package:passtime/widgets/menu_sheet_padding.dart';

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

  Widget _buildMenuSheet(BuildContext context, List<Widget> children) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 8,
          bottom: menuSheetBottomPadding(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
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
              return _buildMenuSheet(
                context,
                [
                        // '입장권' 메뉴
                        _buildMenuItem(
                          context,
                          imagePath: 'assets/images/ticket.png',
                          text: '입장권',
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TicketScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                        // '입장권 추가' 메뉴 - 중첩 바텀시트
                        _buildMenuItem(
                          context,
                          imagePath: 'assets/images/ticket-plus.png',
                          text: '입장권 추가',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return _buildMenuSheet(
                                  context,
                                  [
                                      _buildMenuItem(
                                        context,
                                        imagePath:
                                            'assets/images/ticket-plus.png',
                                        text: 'CODE로 추가',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const AddTicketCodeScreen()),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        context,
                                        imagePath:
                                            'assets/images/ticket-plus.png',
                                        text: 'NFC로 추가',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const AddTicketNfcScreen()),
                                          );
                                        },
                                      ),
                                    ],
                                );
                              },
                            ).then((_) {
                              if (mounted) {
                                setState(() {
                                  _isMenuOpen = false;
                                });
                              }
                            });
                          },
                        ),
                        // '납부 내역 보내기' 메뉴
                        _buildMenuItem(
                          context,
                          imagePath: 'assets/images/coins-stacked.png',
                          text: '납부 내역 보내기',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SendPaymentScreen()),
                            );
                          },
                        ),
                        // '환불 신청' 메뉴
                        _buildMenuItem(
                          context,
                          imagePath: 'assets/images/coins-out.png',
                          text: '환불 신청',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RequestRefundScreen()),
                            );
                          },
                        ),
                        // '마이페이지' 메뉴
                        _buildMenuItem(
                          context,
                          imagePath: 'assets/images/user.png',
                          text: '마이페이지',
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyPageScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                        // '주최자 모드' 메뉴
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            navigateToOrganizerMode(context, dio);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/user-check.png',
                                  width: 24,
                                  height: 24,
                                  color: const Color(0xFF7E929F),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  '주최자 모드',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // '설정' 메뉴
                        _buildMenuItem(
                          context,
                          imagePath: 'assets/images/settings.png',
                          text: '설정',
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                ],
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
