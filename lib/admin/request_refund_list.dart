import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class RequestRefundListScreen extends StatelessWidget {
  const RequestRefundListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar:
          CustomAppBar(title: "환불 신청 목록", backgroundColor: Color(0xFF282727)),
    );
  }
}
