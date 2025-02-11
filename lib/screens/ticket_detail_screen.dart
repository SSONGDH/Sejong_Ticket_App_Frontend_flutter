import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class TicketDetailScreen extends StatelessWidget {
  final String title;
  final Color appBarColor;

  const TicketDetailScreen(
      {super.key, required this.title, required this.appBarColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 배경색 통일
      appBar: const CustomAppBar(
          title: "입장권", backgroundColor: Color(0xFFB93234)), // ✅ 동적 색상 적용
      body: Center(
        child: Text(
          '$title의 상세 내용',
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
