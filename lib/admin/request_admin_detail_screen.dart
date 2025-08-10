import 'package:flutter/material.dart';

class RequestAdminDetailScreen extends StatelessWidget {
  const RequestAdminDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.black,
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "주최자 신청 상세",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFEEEDE3),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoContainer(label: "이름", value: "윤재민"),
                    const SizedBox(height: 12),
                    _buildInfoContainer(label: "학번", value: "24011184"),
                    const SizedBox(height: 12),
                    _buildInfoContainer(label: "전화번호", value: "010-5265-4339"),
                    const SizedBox(height: 12),
                    _buildInfoContainer(label: "소속", value: "아롬"),
                    const SizedBox(height: 12),
                    _buildInfoContainer(label: "권한 여부", value: "예"),
                    const SizedBox(height: 12),
                    _buildInfoContainer(label: "생성 여부", value: "아니오"),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 승인 버튼 로직 구현
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334D61),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "승인",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
