import 'package:flutter/material.dart';
import 'ticket_screen.dart';
import 'package:passtime/widgets/click_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRememberId = true; // 아이디 저장 여부
  bool isAutoLogin = false; // 자동 로그인 여부
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 화면 클릭하면 키보드 닫힘
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

                // 입력 필드
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
                const SizedBox(height: 15),

                // 아이디 저장 & 자동 로그인 토글
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildToggleOption(
                      text: '아이디저장',
                      isSelected: isRememberId,
                      onTap: () {
                        setState(() {
                          isRememberId = !isRememberId;
                        });
                      },
                    ),
                    _buildToggleOption(
                      text: '자동로그인',
                      isSelected: isAutoLogin,
                      onTap: () {
                        setState(() {
                          isAutoLogin = !isAutoLogin;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // 로그인 버튼 (CustomButton 적용)
                CustomButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TicketScreen(),
                      ),
                    );
                  },
                  color: const Color(0xFFB93234), // 빨간색 버튼
                  child: const Text(
                    '로그인',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

                const SizedBox(height: 60),

                // 하단 텍스트
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

  /// ✅ 입력 필드 위젯
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

  /// ✅ 토글 버튼 위젯 (아이디 저장 & 자동 로그인)
  Widget _buildToggleOption({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFB93234) : Colors.grey,
                width: 2,
              ),
              color: isSelected ? const Color(0xFFB93234) : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
