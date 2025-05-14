import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/screens/ticket_screen.dart';
import 'package:passtime/widgets/app_bar.dart';

class AddTicketNfcScreen extends StatefulWidget {
  const AddTicketNfcScreen({super.key});

  @override
  State<AddTicketNfcScreen> createState() => _AddTicketNfcScreenState();
}

class _AddTicketNfcScreenState extends State<AddTicketNfcScreen> {
  final bool _isLoading = false;
  String? _nfcId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "NFC",
        backgroundColor: Color(0xFFB93234),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _nfcId == null
                ? const Text(
                    'NFC 태그를 가까이 대주세요',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  )
                : Text(
                    '스캔 완료: $_nfcId',
                    style: const TextStyle(fontSize: 18, color: Colors.green),
                  ),
      ),
    );
  }
}
