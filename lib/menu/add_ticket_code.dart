import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class AddTicketCodeScreen extends StatelessWidget {
  const AddTicketCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "CODE", backgroundColor: Color(0xFFB93234)),
    );
  }
}
