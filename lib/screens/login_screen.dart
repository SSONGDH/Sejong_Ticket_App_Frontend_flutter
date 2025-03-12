import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:passtime/widgets/click_button.dart';
import 'ticket_screen.dart';
import '../cookiejar_singleton.dart'; // CookieJarSingleton import 추가

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
        CookieManager(CookieJarSingleton().cookieJar)); // CookieJarSingleton 사용
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
    final String url = '$baseUrl/login';

    try {
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
        // 로그인 성공 후 쿠키 저장 확인
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final uri = Uri.parse(baseUrl); // base URL을 URI로 변환
          final parsedCookies = cookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();

          // 쿠키를 CookieJarSingleton에 저장
          await CookieJarSingleton()
              .cookieJar
              .saveFromResponse(uri, parsedCookies);

          // 로그인 성공 시 TicketScreen으로 이동
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
