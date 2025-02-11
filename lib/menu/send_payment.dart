import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class SendPaymentScreen extends StatelessWidget {
  const SendPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // ✅ 배경색 통일
      appBar:
          CustomAppBar(title: "납부내역 보내기", backgroundColor: Color(0xFFB93234)),
      body: Center(
        child: Text(
          "납부내역을 보낼 수 있습니다.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
