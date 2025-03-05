import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class TicketProduceScreen extends StatelessWidget {
  const TicketProduceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "행사 제작", backgroundColor: Color(0xFF282727)),
    );
  }
}
