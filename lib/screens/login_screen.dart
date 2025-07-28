import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ticket_screen.dart';
import '../cookiejar_singleton.dart';
import 'package:flutter/cupertino.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRememberId = false;
  bool isAutoLogin = false;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(
      CookieManager(CookieJarSingleton().cookieJar),
    );
    _idController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  @override
  void dispose() {
    _idController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final String url = '$baseUrl/auth/login';

    try {
      print('🚀 로그인 요청 URI: $url');
      print(
          '📝 로그인 요청 데이터: { "userId": "${_idController.text.trim()}", "password": "******" }');

      final response = await _dio.post(
        url,
        data: {
          "userId": _idController.text.trim(),
          "password": _passwordController.text.trim(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final uri = Uri.parse(baseUrl);
          final parsedCookies = cookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();
          await CookieJarSingleton()
              .cookieJar
              .saveFromResponse(uri, parsedCookies);

          try {
            String? fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              print('FCM Token: $fcmToken');

              final fcmUrl = '$baseUrl/fcm/tokenAdd';
              print('🚀 FCM 토큰 전송 URI: $fcmUrl');
              print('📝 FCM 토큰 전송 데이터: { "fcmToken": "$fcmToken" }');

              final fcmResponse = await _dio.post(
                fcmUrl,
                data: {"fcmToken": fcmToken},
                options: Options(
                  headers: {
                    'Content-Type': 'application/json',
                  },
                ),
              );

              if (fcmResponse.statusCode == 200) {
                print('✅ FCM 토큰 서버 전송 성공');
              } else {
                print('⚠️ FCM 토큰 서버 전송 실패: ${fcmResponse.statusCode}');
              }
            } else {
              print('FCM Token을 가져오지 못했습니다.');
            }
          } catch (e) {
            print('FCM 토큰 요청/전송 중 오류 발생: $e');
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TicketScreen()),
          );
        } else {
          _showErrorDialog('로그인 실패: 쿠키를 받을 수 없습니다.');
        }
      } else {
        _showErrorDialog('로그인 실패');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('학번과 비밀번호가 일치하지 않습니다.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFFC10230)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInputComplete = _idController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    const Color activeBtnColor = Color(0xFFC10230);
    final Color disabledBtnColor = activeBtnColor.withOpacity(0.3);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 150),
                Image.asset(
                  'assets/images/sejong.png',
                  width: 180,
                  height: 160,
                ),
                const SizedBox(height: 80),
                _buildInputField(
                  controller: _idController,
                  focusNode: _idFocusNode,
                  hintText: '아이디를 입력하세요',
                  icon: Icons.person_outline_rounded,
                  isPassword: false,
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hintText: '비밀번호를 입력하세요',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 15),
                _buildRememberAndAutoLogin(),
                const SizedBox(height: 50),
                SizedBox(
                  width: 326,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeBtnColor,
                      disabledBackgroundColor: disabledBtnColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: isInputComplete
                        ? () {
                            if (!_isLoading) {
                              _login();
                            }
                          }
                        : null,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            '로그인',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required bool isPassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF334D61),
            size: 26,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRememberAndAutoLogin() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isRememberId = !isRememberId;
              });
            },
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isRememberId,
                    onChanged: (bool? newValue) {
                      setState(() {
                        isRememberId = newValue!;
                      });
                    },
                    activeColor: const Color(0xFFC10230),
                    checkColor: Colors.white,
                    side: BorderSide.none,
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFC10230);
                        }
                        return const Color(0xFF334D61).withOpacity(0.05);
                      },
                    ),
                    shape: const CircleBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Text(' 아이디 저장', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          InkWell(
            // InkWell 추가
            onTap: () {
              setState(() {
                isAutoLogin = !isAutoLogin;
              });
            },
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isAutoLogin,
                    onChanged: (bool? newValue) {
                      setState(() {
                        isAutoLogin = newValue!;
                      });
                    },
                    activeColor: const Color(0xFFC10230),
                    checkColor: Colors.white,
                    side: BorderSide.none,
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFC10230);
                        }
                        return const Color(0xFF334D61).withOpacity(0.05);
                      },
                    ),
                    shape: const CircleBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Text(' 자동 로그인', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
