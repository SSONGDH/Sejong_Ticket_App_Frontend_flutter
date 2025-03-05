import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class SendPaymentListScreen extends StatelessWidget {
  const SendPaymentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar:
          CustomAppBar(title: "납부 내역 목록", backgroundColor: Color(0xFF282727)),
    );
  }
}
