import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';
import 'package:dio/dio.dart'; // Dio import
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart'; // CookieJarSingleton import

class AddTicketCodeScreen extends StatefulWidget {
  const AddTicketCodeScreen({super.key});

  @override
  _AddTicketCodeScreenState createState() => _AddTicketCodeScreenState();
}

class _AddTicketCodeScreenState extends State<AddTicketCodeScreen> {
  final TextEditingController _controller = TextEditingController();

  // 서버에 코드 전송하는 함수
  Future<void> _addTicketCode(String eventCode) async {
    final apiUrl =
        '${dotenv.env['API_BASE_URL']}/ticket/add'; // .env 파일에서 API_BASE_URL을 가져옴
    final dio = Dio(); // Dio 객체 생성
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final ssotoken = await CookieJarSingleton().cookieJar.loadForRequest(uri);

    print(ssotoken);

    // 요청 본문 출력
    final requestBody = json.encode({'eventCode': eventCode});
    print('Request Body: $requestBody'); // 요청 본문 출력

    try {
      final response = await dio.post(
        apiUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': ssotoken, // SSO 토큰을 Cookie 헤더에 포함
          },
        ),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.data}'); // 응답 본문 출력

      if (response.statusCode == 200) {
        // 성공적인 응답 처리
        final responseBody = response.data;
        if (responseBody['isSuccess']) {
          // 성공적인 티켓 생성 메시지 처리
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('티켓이 성공적으로 생성되었습니다!')),
          );
        } else {
          // 실패 메시지 처리
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('코드 입력이 잘못되었습니다.')),
          );
        }
      } else {
        // 서버와 연결할 수 없거나 다른 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버와 연결할 수 없습니다. 다시 시도해 주세요.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      // 예외 발생 시 처리
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
            // 코드가 입력되지 않은 경우 처리
            final eventCode = _controller.text.trim();
            if (eventCode.isNotEmpty) {
              _addTicketCode(eventCode); // 서버에 코드 전송
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
