import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/menu_button.dart';
import 'package:passtime/menu/my_request_detail_screen.dart';
import 'package:passtime/utils/affiliation_api_parser.dart';

class MyRequestHistoryScreen extends StatefulWidget {
  const MyRequestHistoryScreen({super.key});

  @override
  State<MyRequestHistoryScreen> createState() => _MyRequestHistoryScreenState();
}

class _MyRequestHistoryScreenState extends State<MyRequestHistoryScreen> {
  final Dio _dio = Dio();
  late Future<List<Map<String, dynamic>>> _requestsFuture = fetchRequests();

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

    _requestsFuture = fetchRequests();
  }

  Future<List<Map<String, dynamic>>> fetchRequests() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/user/mypage/requests';
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
        ),
      );

      if (response.data['code'] == 'SUCCESS-0000') {
        final result = response.data['result'] as Map<String, dynamic>? ?? {};
        final requests = result['requests'];
        if (requests is List) {
          return requests
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = fetchRequests();
    });
    await _requestsFuture;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF334D61);
      case 'rejected':
        return const Color(0xFFC10230);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status']?.toString() ?? 'pending';
    final statusLabel =
        request['statusLabel']?.toString() ?? '승인 대기';
    final requestTypeLabel =
        AffiliationApiParser.resolveRequestTypeLabel(request);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyRequestDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestTypeLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334D61),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request['affiliationName']?.toString() ?? '-',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '신청일 ${_formatDate(request['createdAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 57,
                height: 24,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: const CustomAppBar(title: '신청 내역'),
      body: RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.white,
        onRefresh: _refreshRequests,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _requestsFuture,
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
                      '신청 내역을 불러오지 못했습니다',
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

            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: const Color(0xFF334D61).withOpacity(0.25),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '신청 내역이 없습니다',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334D61),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildRequestCard(requests[index]),
            );
          },
        ),
      ),
      floatingActionButton: const MenuButton(),
    );
  }
}
