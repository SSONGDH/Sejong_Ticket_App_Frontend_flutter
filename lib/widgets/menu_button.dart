import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';
import 'package:PASSTIME/screens/ticket_screen.dart';
import 'package:PASSTIME/menu/add_ticket_code.dart';
import 'package:PASSTIME/menu/add_ticket_nfc.dart';
import 'package:PASSTIME/menu/send_payment.dart';
import 'package:PASSTIME/menu/request_refund.dart';
import 'package:PASSTIME/menu/my_page_screen.dart';
import 'package:PASSTIME/menu/settings.dart';
import 'package:PASSTIME/admin/admin_ticket_screen.dart';

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
  // ⭐ IconData 대신 String imagePath로 변경 ⭐
  Widget _buildMenuItem(BuildContext context,
      {required String imagePath, // 이미지 경로로 변경
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
            // ⭐ Icon 대신 Image.asset 사용 ⭐
            Image.asset(
              imagePath,
              width: 24, // 아이콘과 유사한 크기로 설정
              height: 24, // 아이콘과 유사한 크기로 설정
              color: Colors.grey[700], // 아이콘 색상처럼 이미지에 색상 오버레이 가능 (필요 없으면 제거)
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
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
                      // '입장권' 메뉴
                      _buildMenuItem(
                        context,
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath: 'assets/images/menu_ticket.png', // 예시 이미지 경로
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
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath:
                            'assets/images/menu_add_ticket.png', // 예시 이미지 경로
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
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildMenuItem(
                                    context,
                                    // ⭐ 이미지 경로 지정 ⭐
                                    imagePath:
                                        'assets/images/menu_add_ticket.png', // 예시 이미지 경로
                                    text: 'CODE',
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
                                    // ⭐ 이미지 경로 지정 ⭐
                                    imagePath:
                                        'assets/images/menu_add_ticket.png', // 예시 이미지 경로
                                    text: 'NFC',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AddTicketNfcScreen(),
                                        ),
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
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath:
                            'assets/images/menu_send_payment.png', // 예시 이미지 경로
                        text: '납부 내역 보내기',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SendPaymentScreen()),
                          );
                        },
                      ),
                      // '환불 신청' 메뉴
                      _buildMenuItem(
                        context,
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath:
                            'assets/images/menu_request_refund.png', // 예시 이미지 경로
                        text: '환불 신청',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RequestRefundScreen()),
                          );
                        },
                      ),
                      // '마이페이지' 메뉴
                      _buildMenuItem(
                        context,
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath:
                            'assets/images/menu_my_page.png', // 예시 이미지 경로
                        text: '마이페이지',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyPageScreen()),
                          );
                        },
                      ),
                      // '설정' 메뉴
                      _buildMenuItem(
                        context,
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath:
                            'assets/images/menu_setting.png', // 예시 이미지 경로
                        text: '설정',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      // '주최자 모드' 메뉴
                      _buildMenuItem(
                        context,
                        // ⭐ 이미지 경로 지정 ⭐
                        imagePath: 'assets/images/menu_admin.png', // 예시 이미지 경로
                        text: '주최자 모드',
                        onTap: () async {
                          try {
                            final apiUrl =
                                '${dotenv.env['API_BASE_URL']}/admin/connection';
                            final uri =
                                Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
                            final cookies = await CookieJarSingleton()
                                .cookieJar
                                .loadForRequest(uri);

                            final response = await dio.get(
                              apiUrl,
                              options: Options(headers: {'Cookie': cookies}),
                            );

                            if (response.statusCode == 200 &&
                                response.data['isSuccess'] == true) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminTicketScreen()),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('알림'),
                                  content: const Text('지정된 관리자가 아닙니다.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('주최자 모드 접속 중 오류가 발생했습니다.')),
                            );
                          }
                        },
                      ),
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
