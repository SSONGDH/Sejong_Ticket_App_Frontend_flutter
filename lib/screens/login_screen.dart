import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ticket_screen.dart';
import '../cookiejar_singleton.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _obscurePassword = true;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(
      CookieManager(CookieJarSingleton().cookieJar),
    );
    _loadLoginData();
    _idController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  Future<void> _loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberId = prefs.getBool('isRememberId') ?? false;
    final autoLogin = prefs.getBool('isAutoLogin') ?? false;
    final userId = prefs.getString('userId') ?? '';
    final password = autoLogin ? (prefs.getString('password') ?? '') : '';

    if (!mounted) return;
    setState(() {
      isRememberId = rememberId;
      isAutoLogin = autoLogin;
      if (rememberId || autoLogin) {
        _idController.text = userId;
      }
      if (autoLogin) {
        _passwordController.text = password;
      }
    });

    if (autoLogin && userId.isNotEmpty && password.isNotEmpty) {
      await _performLogin(userId, password, isAutoLoginAttempt: true);
    }
  }

  Future<void> _saveLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isRememberId', isRememberId);
    prefs.setBool('isAutoLogin', isAutoLogin);

    if (isRememberId || isAutoLogin) {
      prefs.setString('userId', _idController.text.trim());
    } else {
      prefs.remove('userId');
    }

    if (isAutoLogin) {
      prefs.setString('password', _passwordController.text.trim());
    } else {
      prefs.remove('password');
    }
  }

  Future<void> _clearAutoLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoLogin', false);
    await prefs.remove('password');
    if (!mounted) return;
    setState(() {
      isAutoLogin = false;
      _passwordController.clear();
    });
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
    await _performLogin(
      _idController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  Future<void> _performLogin(
    String userId,
    String password, {
    bool isAutoLoginAttempt = false,
  }) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final String url = '$baseUrl/auth/login';

    try {
      final response = await _dio.post(
        url,
        data: {
          "userId": userId,
          "password": password,
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
              final fcmUrl = '$baseUrl/fcm/tokenAdd';
              await _dio.post(
                fcmUrl,
                data: {"fcmToken": fcmToken},
                options: Options(
                  headers: {
                    'Content-Type': 'application/json',
                  },
                ),
              );
            }
          } catch (e) {
            print('FCM 토큰 요청/전송 중 오류 발생: $e');
          }

          if (isAutoLogin) {
            isRememberId = true;
          }
          await _saveLoginData();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TicketScreen()),
          );
        } else {
          if (isAutoLoginAttempt) {
            await _clearAutoLoginData();
          }
          _showErrorDialog('로그인 실패: 쿠키를 받을 수 없습니다.');
        }
      } else {
        if (isAutoLoginAttempt) {
          await _clearAutoLoginData();
        }
        _showErrorDialog('로그인 실패');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (isAutoLoginAttempt) {
        await _clearAutoLoginData();
        _showErrorDialog('자동 로그인에 실패했습니다. 다시 로그인해주세요.');
      } else {
        _showErrorDialog('학번과 비밀번호가 일치하지 않습니다.');
      }
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
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF334D61),
            size: 26,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF334D61),
                    size: 22,
                  ),
                )
              : null,
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
          _buildLoginOption(
            value: isRememberId,
            label: '아이디 저장',
            onChanged: (newValue) {
              setState(() {
                isRememberId = newValue;
                if (!isRememberId && !isAutoLogin) {
                  _idController.clear();
                }
              });
              _saveLoginData();
            },
          ),
          _buildLoginOption(
            value: isAutoLogin,
            label: '자동 로그인',
            onChanged: (newValue) {
              setState(() {
                isAutoLogin = newValue;
                if (isAutoLogin) {
                  isRememberId = true;
                }
              });
              _saveLoginData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginOption({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (bool? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
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
          Text(' $label', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
