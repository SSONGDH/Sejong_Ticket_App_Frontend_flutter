import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class RequestRefundScreen extends StatelessWidget {
  const RequestRefundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "환불 신청", backgroundColor: Color(0xFFB93234)),
      body: Center(
        child: Text(
          "환불을 신청할 수 있습니다.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
