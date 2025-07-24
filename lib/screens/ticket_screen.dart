import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:PASSTIME/widgets/app_bar.dart';
import 'package:PASSTIME/widgets/ticket_card.dart';
import '../cookiejar_singleton.dart';
import 'package:PASSTIME/menu/add_ticket_code.dart';
import 'package:PASSTIME/menu/add_ticket_nfc.dart';
import 'package:PASSTIME/admin/admin_ticket_screen.dart';
import 'package:PASSTIME/menu/request_refund.dart';
import 'package:PASSTIME/menu/send_payment.dart';
import 'package:PASSTIME/menu/settings.dart';

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
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
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

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['isSuccess'] == true) {
          return List<Map<String, dynamic>>.from(data['result']);
        } else {
          throw Exception('No tickets found.');
        }
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '승인됨':
        return const Color(0xFF6035FB);
      case '미승인':
        return const Color(0xFF9E9E9E);
      case '환불중':
        return const Color(0xFFDE4244);
      case '환불됨':
        return const Color(0xFF282727);
      case '만료됨':
        return const Color(0xFF282727);
      default:
        return const Color(0xFF9E9E9E);
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
                } else if (snapshot.hasError ||
                    !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
                  return const Center(
                    child: Text(
                      '현재 발급된 입장권이 없습니다',
                      style: TextStyle(fontSize: 22, color: Color(0xFFC1C1C1)),
                    ),
                  );
                } else {
                  final tickets = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return TicketCard(
                          ticketId: ticket['_id'],
                          title: ticket['eventTitle'],
                          dateTime:
                              '${ticket['eventDay']} / ${ticket['eventStartTime']}',
                          location: ticket['eventPlace'],
                          status: '${ticket['status']}',
                          statusColor: _getStatusColor(ticket['status']),
                          appBarColor: const Color(0xFF6035FB),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
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
                          builder: (_) => const SendPaymentScreen()),
                    ),
                  ),
                  ListTile(
                    title: const Text('입장권 추가'),
                    onTap: () {
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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddTicketCodeScreen()),
                                ),
                              ),
                              ListTile(
                                title: const Text('NFC'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddTicketNfcScreen(),
                                  ),
                                ),
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
                          builder: (_) => const RequestRefundScreen()),
                    ),
                  ),
                  ListTile(
                    title: const Text('설정'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  ListTile(
                    title: const Text('관리자 모드'),
                    onTap: () async {
                      try {
                        final apiUrl =
                            '${dotenv.env['API_BASE_URL']}/admin/connection';
                        final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
                        final cookies = await CookieJarSingleton()
                            .cookieJar
                            .loadForRequest(uri);

                        final response = await _dio.get(
                          apiUrl,
                          options: Options(headers: {'Cookie': cookies}),
                        );

                        if (response.statusCode == 200 &&
                            response.data['isSuccess'] == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminTicketScreen()),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('알림'),
                              content: const Text('지정된 관리자가 아닙니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('관리자 모드 접속 중 오류가 발생했습니다.')),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFFB93234),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
