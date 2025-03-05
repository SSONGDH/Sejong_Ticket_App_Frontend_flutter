import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class TicketEditScreen extends StatelessWidget {
  const TicketEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "행사 수정", backgroundColor: Color(0xFF282727)),
    );
  }
}
