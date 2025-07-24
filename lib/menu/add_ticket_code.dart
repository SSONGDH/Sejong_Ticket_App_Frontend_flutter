import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/app_bar.dart';
import 'package:PASSTIME/widgets/click_button.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart';
import 'package:PASSTIME/screens/ticket_screen.dart';

class AddTicketCodeScreen extends StatefulWidget {
  const AddTicketCodeScreen({super.key});

  @override
  _AddTicketCodeScreenState createState() => _AddTicketCodeScreenState();
}

class _AddTicketCodeScreenState extends State<AddTicketCodeScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _addTicketCode(String eventCode) async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/add';
    final dio = Dio();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final ssotoken = await CookieJarSingleton().cookieJar.loadForRequest(uri);

    final requestBody = json.encode({'eventCode': eventCode});
    print('Request Body: $requestBody');

    try {
      final response = await dio.post(
        apiUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': ssotoken,
          },
        ),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final responseBody = response.data;
        if (responseBody['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('입장권이 생성되었습니다!')),
          );

          // 1초 후 TicketScreen으로 이동
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TicketScreen()),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('코드 입력이 잘못되었습니다.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버와 연결할 수 없습니다. 다시 시도해 주세요.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 연결할 수 없습니다. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          const CustomAppBar(title: "CODE", backgroundColor: Color(0xFFB93234)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "코드 입력",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "코드를 입력하세요",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30),
        child: CustomButton(
          onPressed: () {
            final eventCode = _controller.text.trim();
            if (eventCode.isNotEmpty) {
              _addTicketCode(eventCode);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('코드를 입력해 주세요.')),
              );
            }
          },
          color: const Color(0xFFB93234),
          borderRadius: 5,
          height: 55,
          child: const Text(
            "확인",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
