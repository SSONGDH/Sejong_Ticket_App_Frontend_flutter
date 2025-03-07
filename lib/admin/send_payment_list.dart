import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'send_payment_detail_screen.dart';
import 'package:passtime/widgets/app_bar.dart';

class SendPaymentListScreen extends StatefulWidget {
  const SendPaymentListScreen({super.key});

  @override
  _SendPaymentListScreenState createState() => _SendPaymentListScreenState();
}

class _SendPaymentListScreenState extends State<SendPaymentListScreen> {
  final Map<String, bool> _switchValues = {
    "24011184": false,
    "24012357": false,
  };

  final Map<String, String> _studentNames = {
    "24011184": "윤재민",
    "24012357": "김정현",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "납부 내역 목록", backgroundColor: Color(0xFF282727)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: _studentNames.keys.map((id) => _buildListItem(id)).toList(),
        ),
      ),
    );
  }

  Widget _buildListItem(String id) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SendPaymentDetailScreen(
              studentId: id,
              name: _studentNames[id] ?? "이름 없음",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              id,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _studentNames[id] ?? "이름 없음",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            CupertinoSwitch(
              value: _switchValues[id] ?? false,
              activeColor: const Color(0xFFB93234),
              onChanged: (bool value) {
                setState(() {
                  _switchValues[id] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
