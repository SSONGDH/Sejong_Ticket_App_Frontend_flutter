import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/admin/request_admin_detail_screen.dart';

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
      'studentId': '24011184',
      'department': '아롬',
      'name': '윤재민',
      'status': '미승인',
      'isApproved': false,
    },
    {
      'studentId': '24012357',
      'department': '아롬',
      'name': '김정현',
      'status': '미승인',
      'isApproved': false,
    },
    {
      'studentId': '학번',
      'department': '소속',
      'name': '이름',
      'status': '승인됨',
      'isApproved': true,
    },
    {
      'studentId': '학번',
      'department': '소속',
      'name': '이름',
      'status': '승인됨',
      'isApproved': true,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: _adminRequests.length,
                    itemBuilder: (context, index) {
                      final request = _adminRequests[index];
                      final isApproved = request['isApproved'] as bool;
                      final status = request['status'] as String;
                      final statusColor = isApproved
                          ? const Color(0xFF334D61)
                          : const Color(0xFFC10230);

                      return GestureDetector(
                        onTap: () {
                          // Container를 탭하면 RequestAdminDetailScreen으로 이동합니다.
                          // Navigator.push를 사용하여 새 화면을 스택에 추가합니다.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RequestAdminDetailScreen(),
                            ),
                          );
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
                  ),
          ),
        ],
      ),
      floatingActionButton: const AdminMenuButton(),
    );
  }
}
