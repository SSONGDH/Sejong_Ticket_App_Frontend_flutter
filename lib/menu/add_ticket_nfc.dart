import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class AddTicketNfcScreen extends StatelessWidget {
  const AddTicketNfcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "NFC", backgroundColor: Color(0xFFB93234)),
      body: Center(
        child: Text(
          'NFC 기능을 키고 카드를 대주세요',
          style: TextStyle(fontSize: 22, color: Color(0xFFC1C1C1)),
        ),
      ),
    );
  }
}
