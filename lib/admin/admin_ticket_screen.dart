import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class AdminTicketScreen extends StatelessWidget {
  const AdminTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "행사 관리", backgroundColor: Color(0xFF282727)),
    );
  }
}
