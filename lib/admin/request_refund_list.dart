import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/admin/request_refund_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';

class RequestRefundListScreen extends StatefulWidget {
  const RequestRefundListScreen({super.key});

  @override
  _RequestRefundListScreenState createState() =>
      _RequestRefundListScreenState();
}

class _RequestRefundListScreenState extends State<RequestRefundListScreen> {
  List<Map<String, dynamic>> refundRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRefundRequests();
  }

  Future<void> _fetchRefundRequests() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/refund/refundList');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['isSuccess'] == true) {
          setState(() {
            refundRequests = List<Map<String, dynamic>>.from(
              data['result'].map((refund) {
                return {
                  '_id': refund['_id'],
                  'title': refund['eventName'],
                  'studentInfo': refund['name'],
                  'visitTime':
                      '${refund['visitDate']} / ${refund['visitTime']}',
                  'status': refund['refundPermissionStatus'] == 'TRUE'
                      ? '승인됨'
                      : '미승인',
                  'statusColor': refund['refundPermissionStatus'] == 'TRUE'
                      ? const Color(0xFF6035FB)
                      : const Color(0xFFDE4244),
                  'refundReason': refund['refundReason'],
                };
              }).toList(),
            );
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: refundRequests.length,
                      itemBuilder: (context, index) {
                        final refund = refundRequests[index];
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RequestRefundDetailScreen(
                                    refundId: refund['_id']),
                              ),
                            );
                            if (result == true) {
                              _fetchRefundRequests();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      refund['title']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: refund['statusColor'],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        refund['status']!,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (refund['studentInfo']!.isNotEmpty)
                                  Text("학생 정보  ${refund['studentInfo']}",
                                      style: const TextStyle(fontSize: 14)),
                                if (refund['visitTime']!.isNotEmpty)
                                  Text("방문 시간  ${refund['visitTime']}",
                                      style: const TextStyle(fontSize: 14)),
                                if (refund['refundReason']!.isNotEmpty)
                                  Text("환불 사유  ${refund['refundReason']}",
                                      style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
