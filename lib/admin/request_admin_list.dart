import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';

class RequestAdminListScreen extends StatefulWidget {
  const RequestAdminListScreen({super.key});

  @override
  State<RequestAdminListScreen> createState() => _RequestAdminListScreenState();
}

class _RequestAdminListScreenState extends State<RequestAdminListScreen> {
  // 실제 데이터는 API 호출을 통해 가져와야 합니다.
  // 여기서는 간단한 더미 데이터를 사용합니다.
  final List<Map<String, dynamic>> _adminRequests = [
    {
      'name': '김민준',
      'id': 'minjun.kim',
      'status': '승인 대기 중',
      'statusColor': const Color(0xFFC1C1C1),
    },
    {
      'name': '박서연',
      'id': 'seoyeon.park',
      'status': '승인 대기 중',
      'statusColor': const Color(0xFFC1C1C1),
    },
  ];

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
            child: _adminRequests.isEmpty
                ? const Center(
                    child: Text(
                      '현재 신청 내역이 없습니다.',
                      style: TextStyle(fontSize: 22, color: Color(0xFFC1C1C1)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _adminRequests.length,
                    itemBuilder: (context, index) {
                      final request = _adminRequests[index];
                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: 12, left: 16, right: 16, top: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request['name']!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "아이디: ${request['id']}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // 승인 로직 구현
                                // 예: showDialog를 통해 승인/거절 선택
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: request['statusColor'],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                request['status']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: const AdminMenuButton(),
    );
  }
}
