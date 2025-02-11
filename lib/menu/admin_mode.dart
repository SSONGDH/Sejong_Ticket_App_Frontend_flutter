import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class AdminModeScreen extends StatelessWidget {
  const AdminModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // ✅ 배경색 통일
      appBar: CustomAppBar(title: "관리자 모드", backgroundColor: Color(0xFF282727)),
      body: Center(
        child: Text(
          "관리자 모드를 사용할 수 있습니다.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
