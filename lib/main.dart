import 'package:flutter/material.dart';
import 'screens/ticket_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TicketScreen(), // TicketScreen 클래스를 화면으로 지정
    );
  }
}
