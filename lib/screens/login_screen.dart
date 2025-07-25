import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:PASSTIME/widgets/click_button.dart';
import 'ticket_screen.dart';
import '../cookiejar_singleton.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRememberId = true;
  bool isAutoLogin = false;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  final Dio _dio = Dio(); // Dio 인스턴스

  @override
  void initState() {
    super.initState();
    // 전역에서 관리하는 CookieJar 인스턴스 사용
    _dio.interceptors.add(
      CookieManager(CookieJarSingleton().cookieJar),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus(); // 키보드 닫기
    setState(() => _isLoading = true); // 로딩 시작

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

          // FCM 토큰 발급 및 서버 전송
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
      builder: (context) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 110),
                Image.asset(
                  'assets/images/sejong_logo.png',
                  width: 175,
                  height: 175,
                ),
                const SizedBox(height: 110),
                _buildInputField(
                  controller: _idController,
                  focusNode: _idFocusNode,
                  hintText: '아이디를 입력하세요',
                  icon: Icons.person,
                  isPassword: false,
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hintText: '비밀번호를 입력하세요',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 50),
                CustomButton(
                  onPressed: _login,
                  color: const Color(0xFFB93234),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '로그인',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
                const SizedBox(height: 60),
                const Text(
                  'PASSTIME',
                  style: TextStyle(fontSize: 22, color: Colors.grey),
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
