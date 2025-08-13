import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'send_payment_detail_screen.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';

class SendPaymentListScreen extends StatefulWidget {
  const SendPaymentListScreen({super.key});

  @override
  _SendPaymentListScreenState createState() => _SendPaymentListScreenState();
}

class _SendPaymentListScreenState extends State<SendPaymentListScreen> {
  Map<String, bool> _switchValues = {};
  Map<String, Map<String, String>> _paymentData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/payment/list');
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await http.get(
        url,
        headers: {
          'Cookie': cookieHeader,
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isSuccess'] == true) {
          setState(() {
            _paymentData = {};
            _switchValues = {};

            for (var payment in data['result']) {
              final studentId = payment['studentId'];
              final name = payment['name'];
              final paymentId = payment['paymentId'];

              _paymentData[paymentId] = {
                'name': name,
                'studentId': studentId,
              };
              _switchValues[paymentId] =
                  payment['paymentPermissionStatus'] == 'TRUE';
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
    required bool newValue,
  }) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String apiUrl =
        newValue ? "$baseUrl/payment/permission" : "$baseUrl/payment/deny";
    final uri = Uri.parse("$apiUrl?paymentId=$paymentId");
    final baseUri = Uri.parse(baseUrl);

    try {
      final cookies =
          await CookieJarSingleton().cookieJar.loadForRequest(baseUri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await http.put(
        uri,
        headers: {
          'Cookie': cookieHeader,
        },
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["isSuccess"] == true) {
        setState(() {
          _switchValues[paymentId] = newValue;
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
        _revertSwitch(paymentId);
        _showErrorDialog(data["message"] ?? "처리에 실패했습니다.");
      }
    } catch (e) {
      _revertSwitch(paymentId);
      _showErrorDialog("상태 변경 중 오류 발생: $e");
    }
  }

  void _revertSwitch(String paymentId) {
    setState(() {
      _switchValues[paymentId] = !_switchValues[paymentId]!;
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
      appBar: const CustomAppBar(title: "납부 내역 목록"),
      floatingActionButton: const AdminMenuButton(),
      body: Column(
        children: [
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEDE3),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _paymentData.isEmpty
                      ? Center(
                          child: Align(
                            alignment: const Alignment(0.0, -0.15),
                            child: Text(
                              '납부 내역 목록이 없습니다',
                              style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      const Color(0xFF334D61).withOpacity(0.5),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : ListView(
                          children: _paymentData.keys
                              .map((paymentId) => _buildListItem(paymentId))
                              .toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String paymentId) {
    final name = _paymentData[paymentId]?['name'] ?? "이름 없음";
    final studentId = _paymentData[paymentId]?['studentId'] ?? "ID 없음";

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
              studentId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            CupertinoSwitch(
              value: _switchValues[paymentId] ?? false,
              activeTrackColor: const Color(0xFFB93234),
              onChanged: (bool value) {
                _toggleApproval(
                  paymentId: paymentId,
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
