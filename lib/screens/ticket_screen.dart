import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/ticket_card.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/menu/add_ticket_code.dart';
import 'package:passtime/menu/add_ticket_nfc.dart';
import 'package:passtime/admin/admin_ticket_screen.dart';
import 'package:passtime/menu/request_refund.dart';
import 'package:passtime/menu/send_payment.dart';
import 'package:passtime/menu/settings.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);

        options.headers['Cookie'] = cookies.isNotEmpty
            ? cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ')
            : '';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final responseCookies = response.headers['set-cookie'];
        if (responseCookies != null && responseCookies.isNotEmpty) {
          final parsedCookies = responseCookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();
          CookieJarSingleton().cookieJar.saveFromResponse(uri, parsedCookies);

          _checkStoredCookies();
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));

    _checkStoredCookies();
  }

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

  Future<List<Map<String, dynamic>>> fetchTickets() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/main';
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookieHeader,
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Response Data: $data');
        if (data['isSuccess'] == true) {
          return List<Map<String, dynamic>>.from(data['result']);
        } else {
          throw Exception('No tickets found.');
        }
      } else if (response.statusCode == 404) {
        print("No tickets found (404 error).");
        return [];
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
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("현재 발급된 입장권이 없습니다"));
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
                                ticketId: ticket['_id'], // ✅ 추가: ticketId 전달
                                title: ticket['eventTitle'],
                                dateTime:
                                    '${ticket['eventDay']} / ${ticket['eventStartTime']}',
                                location: ticket['eventPlace'],
                                status: '사용가능',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white, // ✅ 배경색 고정
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('납부 내역 보내기'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SendPaymentScreen())),
                  ),
                  ListTile(
                    title: const Text('입장권 추가'),
                    onTap: () {
                      // '입장권 추가' 클릭 시 두 번째 하위 메뉴가 뜨도록 추가
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('CODE'),
                                onTap: () {
                                  // CODE 항목 클릭 시 AddTicketCodeScreen으로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AddTicketCodeScreen()),
                                  );
                                },
                              ),
                              ListTile(
                                title: const Text('NFC'),
                                onTap: () {
                                  // NFC 항목 클릭 시 AddTicketNfcScreen으로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AddTicketNfcScreen()),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('환불 신청'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RequestRefundScreen())),
                  ),
                  ListTile(
                    title: const Text('설정'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                  ListTile(
                    title: const Text('관리자 모드'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminTicketScreen())),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFFB93234), // 버튼 색상
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
