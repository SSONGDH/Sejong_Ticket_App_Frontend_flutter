import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/menu_button.dart';
import 'package:passtime/widgets/ticket_card.dart';

class ParticipatedEventsScreen extends StatefulWidget {
  const ParticipatedEventsScreen({super.key});

  @override
  State<ParticipatedEventsScreen> createState() =>
      _ParticipatedEventsScreenState();
}

class _ParticipatedEventsScreenState extends State<ParticipatedEventsScreen> {
  final Dio _dio = Dio();
  late Future<List<Map<String, dynamic>>> _eventsFuture = fetchEvents();

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
      onError: (error, handler) => handler.next(error),
    ));

    _eventsFuture = fetchEvents();
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/user/mypage/events';
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

      if (response.statusCode == 200 && response.data['isSuccess'] == true) {
        return List<Map<String, dynamic>>.from(response.data['result'] ?? []);
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _eventsFuture = fetchEvents();
    });
    await _eventsFuture;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '사용 가능':
        return const Color(0xFFC10230);
      case '만료됨':
        return const Color(0xFF282727);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['status']?.toString() ?? '';
    return TicketCard(
      ticketId: event['ticketId']?.toString() ?? '',
      title: event['eventTitle']?.toString() ?? '',
      dateTime:
          '${event['eventDay']} • ${event['eventStartTime']}',
      location: event['eventPlace']?.toString() ?? '',
      affiliation: event['affiliation']?.toString() ?? '',
      status: status,
      statusColor: _getStatusColor(status),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.event_busy_rounded,
          size: 64,
          color: const Color(0xFF334D61).withOpacity(0.25),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '참여한 행사가 없습니다',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334D61),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '승인된 행사와 종료된 행사만 표시됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF334D61),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: const CustomAppBar(title: '참여 행사'),
      body: RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.white,
        onRefresh: _refreshEvents,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Text(
                      '목록을 불러오지 못했습니다',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334D61).withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            );
          },
        ),
      ),
      floatingActionButton: const MenuButton(),
    );
  }
}
