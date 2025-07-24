import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'send_payment_detail_screen.dart';
import 'package:PASSTIME/widgets/app_bar.dart';
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
  Map<String, Map<String, String>> _studentData = {};
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
            _studentData = {};
            _switchValues = {};

            for (var payment in data['result']) {
              final studentId = payment['studentId'];
              final name = payment['name'];
              final paymentId = payment['paymentId'];
              _studentData[studentId] = {
                'name': name,
                'paymentId': paymentId,
              };
              _switchValues[studentId] =
                  payment['paymentPermissionStatus'] ?? false;
            }
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleApproval({
    required String paymentId,
    required String studentId,
    required bool newValue,
  }) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String apiUrl = newValue
        ? "$baseUrl/payment/paymentPermission"
        : "$baseUrl/payment/paymentDeny";
    final uri = Uri.parse("$apiUrl?paymentId=$paymentId");

    try {
      final response = await http.put(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["isSuccess"] == true) {
        setState(() {
          _switchValues[studentId] = newValue;
        });

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(newValue ? "승인 완료" : "미승인 완료"),
              content:
                  Text(newValue ? "납부 요청이 승인되었습니다." : "납부 요청이 미승인 처리되었습니다."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("확인"),
                ),
              ],
            ),
          );
        }
      } else {
        _revertSwitch(studentId);
        _showErrorDialog(data["message"] ?? "처리에 실패했습니다.");
      }
    } catch (e) {
      _revertSwitch(studentId);
      _showErrorDialog("상태 변경 중 오류 발생: $e");
    }
  }

  void _revertSwitch(String studentId) {
    setState(() {
      _switchValues[studentId] = !_switchValues[studentId]!;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("오류"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
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
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children:
                    _studentData.keys.map((id) => _buildListItem(id)).toList(),
              ),
      ),
    );
  }

  Widget _buildListItem(String id) {
    final name = _studentData[id]?['name'] ?? "이름 없음";
    final paymentId = _studentData[id]?['paymentId'] ?? "";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SendPaymentDetailScreen(paymentId: paymentId),
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
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            CupertinoSwitch(
              value: _switchValues[id] ?? false,
              activeColor: const Color(0xFFB93234),
              onChanged: (bool value) {
                _toggleApproval(
                  paymentId: paymentId,
                  studentId: id,
                  newValue: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
