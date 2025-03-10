import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'screens/login_screen.dart';
import 'admin/admin_ticket_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화 수행
  await dotenv.load(fileName: ".env"); // 환경 변수 로드

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminTicketScreen(),
    );
  }
}
