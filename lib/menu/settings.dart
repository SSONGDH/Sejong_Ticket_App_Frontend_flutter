import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ 배경색 통일
      appBar:
          const CustomAppBar(title: "설정", backgroundColor: Color(0xFFB93234)),
      body: const Center(
        child: Text(
          "앱 설정을 변경할 수 있습니다.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
