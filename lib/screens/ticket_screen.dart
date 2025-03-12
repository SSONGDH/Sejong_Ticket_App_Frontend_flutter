import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/ticket_card.dart';
import '../cookiejar_singleton.dart'; // CookieJarSingleton 임포트

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final Dio _dio = Dio(); // Dio 인스턴스

  @override
  void initState() {
    super.initState();

    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    // Request, Response 인터셉터 추가하여 쿠키 로그 출력
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 쿠키 로드
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);
        if (cookies.isNotEmpty) {
          print(
              "Request Cookies: ${cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')}");
        } else {
          print("No request cookies found.");
        }
        // 쿠키를 요청 헤더에 포함시켜 요청을 보냄
        options.headers['Cookie'] = cookies.isNotEmpty
            ? cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ')
            : '';
        return handler.next(options); // 요청 계속 처리
      },
      onResponse: (response, handler) {
        // 응답에서 쿠키 확인
        final responseCookies = response.headers['set-cookie'];
        if (responseCookies != null && responseCookies.isNotEmpty) {
          print("Response Cookies: ${responseCookies.join('; ')}");

          // 응답에서 쿠키를 쿠키 저장소에 저장
          final parsedCookies = responseCookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();
          CookieJarSingleton().cookieJar.saveFromResponse(uri, parsedCookies);

          // 쿠키가 잘 저장되었는지 확인
          _checkStoredCookies();
        } else {
          print("No response cookies found.");
        }
        return handler.next(response); // 응답 계속 처리
      },
      onError: (error, handler) {
        return handler.next(error); // 오류 계속 처리
      },
    ));

    // 쿠키가 잘 저장되었는지 확인
    _checkStoredCookies();
  }

  // 쿠키 확인 메서드
  Future<void> _checkStoredCookies() async {
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);

    print(uri);

    if (cookies.isNotEmpty) {
      print(
          "Stored Cookies: ${cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')}");
    } else {
      print("No cookies found in CookieJar.");
    }
  }

  // 티켓 정보를 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchTickets() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/main';
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      // 쿠키를 요청 헤더에 포함시키기 위해 로드
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      print("Sending Cookies: $cookieHeader"); // 보내는 쿠키 로그 확인

      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookieHeader, // 쿠키를 헤더에 포함시킴
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['isSuccess'] == true) {
          return List<Map<String, dynamic>>.from(data['result']);
        } else {
          throw Exception('No tickets found.');
        }
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "입장권",
        backgroundColor: Color(0xFFB93234),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16), // 앱바와 티켓 카드 사이에 간격 추가
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("데이터를 불러오지 못했습니다."));
                } else if (snapshot.hasData) {
                  final tickets = snapshot.data ?? [];
                  return tickets.isEmpty
                      ? const Center(
                          child: Text(
                            '현재 발급된 입장권이 없습니다',
                            style: TextStyle(
                                fontSize: 22, color: Color(0xFFC1C1C1)),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            itemCount: tickets.length,
                            itemBuilder: (context, index) {
                              final ticket = tickets[index];
                              return TicketCard(
                                title: ticket['eventTitle'],
                                dateTime:
                                    '${ticket['eventDay']} / ${ticket['eventStartTime']}',
                                location: ticket['eventPlace'],
                                status: '사용가능', // 서버에서 추가되면 변경 가능
                                statusColor: const Color(0xFF6035FB),
                                appBarColor: const Color(0xFF6035FB),
                              );
                            },
                          ),
                        );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
