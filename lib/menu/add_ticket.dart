import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class AddTicketScreen extends StatelessWidget {
  const AddTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ 배경색 통일
      appBar: const CustomAppBar(
          title: "입장권 추가", backgroundColor: Color(0xFFB93234)),
      body: const Center(
        child: Text(
          "새로운 입장권을 추가하세요.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
