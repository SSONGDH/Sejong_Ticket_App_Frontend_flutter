import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class AddTicketNfcScreen extends StatelessWidget {
  const AddTicketNfcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "NFC", backgroundColor: Color(0xFFB93234)),
    );
  }
}
