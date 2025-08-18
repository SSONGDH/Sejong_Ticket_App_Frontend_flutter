import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/admin/request_refund_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';
import 'package:PASSTIME/widgets/refund_ticket_card.dart';
import 'package:flutter/cupertino.dart';

class RequestRefundListScreen extends StatefulWidget {
  const RequestRefundListScreen({super.key});

  @override
  _RequestRefundListScreenState createState() =>
      _RequestRefundListScreenState();
}

class _RequestRefundListScreenState extends State<RequestRefundListScreen> {
  late Future<List<Map<String, dynamic>>> _refundRequestsFuture;

  @override
  void initState() {
    super.initState();
    _refundRequestsFuture = _fetchRefundRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchRefundRequests() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/refund/list');
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
          final List<dynamic> result = data['result'];
          return result.map((refund) {
            return {
              '_id': refund['_id'],
              'title': refund['eventName'],
              'studentInfo': '${refund['studentId']} • ${refund['name']}',
              'visitTime': '${refund['visitDate']} • ${refund['visitTime']}',
              'status':
                  refund['refundPermissionStatus'] == 'TRUE' ? '승인됨' : '미승인',
              'statusColor': refund['refundPermissionStatus'] == 'TRUE'
                  ? const Color(0xFF334D61)
                  : const Color(0xFFC10230),
              'refundReason': refund['refundReason'],
            };
          }).toList();
        } else {
          // 데이터 불러오기 실패 시 빈 리스트 반환
          return [];
        }
      } else {
        // 서버 응답 오류 시 빈 리스트 반환
        return [];
      }
    } catch (error) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "환불 신청 목록"),
      floatingActionButton: const AdminMenuButton(),
      body: Column(
        children: [
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEDE3),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: () async {
                setState(() {
                  _refundRequestsFuture = _fetchRefundRequests();
                });
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _refundRequestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Align(
                      alignment: const Alignment(0.0, -0.15),
                      child: Text(
                        '환불 신청 목록이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF334D61).withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    final refundRequests = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 0),
                      child: ListView.builder(
                        itemCount: refundRequests.length,
                        itemBuilder: (context, index) {
                          final refund = refundRequests[index];
                          return Padding(
                              padding:
                                  EdgeInsets.only(top: index == 0 ? 10.0 : 5.0),
                              child: RefundTicketCard(
                                title: refund['title']!,
                                studentInfo: refund['studentInfo']!,
                                visitTime: refund['visitTime']!,
                                refundReason: refund['refundReason']!,
                                status: refund['status']!,
                                statusColor: refund['statusColor']!,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RequestRefundDetailScreen(
                                          refundId: refund['_id']),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      _refundRequestsFuture =
                                          _fetchRefundRequests();
                                    });
                                  }
                                },
                              ));
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
