import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'send_payment_detail_screen.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SendPaymentListScreen extends StatefulWidget {
  const SendPaymentListScreen({super.key});

  @override
  _SendPaymentListScreenState createState() => _SendPaymentListScreenState();
}

class _SendPaymentListScreenState extends State<SendPaymentListScreen> {
  Map<String, bool> _switchValues = {};
  Map<String, String> _studentNames = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/payment/paymentlist');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isSuccess'] == true) {
          setState(() {
            // 서버 응답에 맞게 데이터 파싱
            _studentNames = {};
            _switchValues = {};

            for (var payment in data['result']) {
              final studentId = payment['studentId'];
              final name = payment['name'];

              _studentNames[studentId] = name;
              _switchValues[studentId] =
                  payment['paymentPermissionStatus'] ?? false;
            }
            isLoading = false;
          });
        } else {
          // 실패한 경우 처리
          setState(() {
            isLoading = false;
          });
        }
      } else {
        // 서버 에러 처리
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      // 네트워크 오류 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "납부 내역 목록", backgroundColor: Color(0xFF282727)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator()) // 로딩 중인 경우
            : ListView(
                children:
                    _studentNames.keys.map((id) => _buildListItem(id)).toList(),
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
