import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/ticket_card.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/widgets/menu_button.dart';
import 'package:flutter/services.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final Dio _dio = Dio();
  late Future<List<Map<String, dynamic>>> _ticketsFuture = fetchTickets();

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
        options.headers['Cookie'] = cookies.isNotEmpty
            ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
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
      case '사용 가능':
        return const Color(0xFFC10230);
      case '사용 불가':
        return const Color(0xFF9E9E9E);
      case '환불중':
        return const Color(0xFF334D61);
      case '환불됨':
        return const Color(0xFF282727);
      case '만료됨':
        return const Color(0xFF282727);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // 팝업창 배경 하얀색
        title: const Text('앱을 종료하시겠습니까?'),
        content: const Text('앱을 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('머무르기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F7),
        appBar: const CustomAppBar(title: '입장권'),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: Colors.black,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  setState(() {
                    _ticketsFuture = fetchTickets();
                  });
                },
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ticketsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError ||
                        !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
                      return Align(
                        alignment: const Alignment(0.0, -0.15),
                        child: Text(
                          '현재 발급된 입장권이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF334D61).withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else {
                      final tickets = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 10.0 : 5.0),
                            child: TicketCard(
                              ticketId: ticket['_id'],
                              title: ticket['eventTitle'],
                              dateTime: '${ticket['eventDay']} • ${ticket['eventStartTime']}',
                              location: ticket['eventPlace'],
                              status: '${ticket['status']}',
                              statusColor: _getStatusColor(ticket['status']),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: const MenuButton(),
      ),
    );
  }
}
