import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/admin/request_admin_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RequestAdminListScreen extends StatefulWidget {
  const RequestAdminListScreen({super.key});

  @override
  State<RequestAdminListScreen> createState() => _RequestAdminListScreenState();
}

class _RequestAdminListScreenState extends State<RequestAdminListScreen> {
  late Future<List<Map<String, dynamic>>> _adminRequestsFuture;

  @override
  void initState() {
    super.initState();
    _adminRequestsFuture = _fetchAdminRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchAdminRequests() async {
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/affiliation/affiliationRequestsList');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = body['result'];

        return results.map((request) {
          final bool isApproved = request['status'] == 'approved';
          return {
            // [수정 1] 상세 페이지로 넘겨줄 id 값을 추가합니다.
            'id': request['_id'] as String,
            'studentId': request['studentId'] as String,
            'department': request['affiliationName'] as String,
            'name': request['name'] as String,
            'status': isApproved ? '승인됨' : '미승인',
            'isApproved': isApproved,
          };
        }).toList();
      } else {
        throw Exception(
            'Failed to load admin requests. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load admin requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "주최자 신청 목록",
      ),
      body: Column(
        children: [
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEDE3),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _adminRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '데이터를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      '현재 신청 내역이 없습니다.',
                      style: TextStyle(fontSize: 22, color: Color(0xFFC1C1C1)),
                    ),
                  );
                }

                final adminRequests = snapshot.data!;
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: adminRequests.length,
                  itemBuilder: (context, index) {
                    final request = adminRequests[index];
                    final isApproved = request['isApproved'] as bool;
                    final status = request['status'] as String;
                    final statusColor = isApproved
                        ? const Color(0xFF334D61)
                        : const Color(0xFFC10230);

                    return GestureDetector(
                      // [수정 2] onTap 이벤트를 수정합니다.
                      onTap: () async {
                        // 상세 페이지로 이동하고, 결과를 받아옵니다. (결과가 true이면 새로고침 필요)
                        final shouldRefresh = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            // request['id']를 requestId 파라미터로 전달합니다.
                            builder: (context) => RequestAdminDetailScreen(
                              requestId: request['id']!,
                            ),
                          ),
                        );

                        // [수정 3] 상세 페이지에서 승인 완료 후 돌아왔다면 목록을 새로고침합니다.
                        if (shouldRefresh == true && mounted) {
                          setState(() {
                            _adminRequestsFuture = _fetchAdminRequests();
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334D61).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      request['studentId']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black.withOpacity(0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      request['department']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black.withOpacity(0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      request['name']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
