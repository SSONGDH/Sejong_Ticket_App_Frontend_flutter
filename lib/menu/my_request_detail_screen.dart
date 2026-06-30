import 'package:flutter/material.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/menu_button.dart';

class MyRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> request;

  const MyRequestDetailScreen({
    super.key,
    required this.request,
  });

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.${parsed.day.toString().padLeft(2, '0')}';
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

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.55),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status']?.toString() ?? 'pending';
    final statusLabel = request['statusLabel']?.toString() ?? '승인 대기';
    final requestTypeLabel =
        request['requestTypeLabel']?.toString() ?? '신청';
    final adminComment = request['adminComment']?.toString() ?? '';
    final introduction = request['introduction']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: const CustomAppBar(title: '신청 상세'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requestTypeLabel,
                          style: const TextStyle(
                            fontSize: 18,
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
                        ),
                      ],
                    ),
                  ),
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
            const SizedBox(height: 10),
            _buildInfoRow('신청일', _formatDate(request['createdAt'])),
            const SizedBox(height: 10),
            _buildInfoRow('이름', request['name']?.toString() ?? ''),
            const SizedBox(height: 10),
            _buildInfoRow('학번', request['studentId']?.toString() ?? ''),
            const SizedBox(height: 10),
            _buildInfoRow('전공', request['major']?.toString() ?? ''),
            const SizedBox(height: 10),
            _buildInfoRow('연락처', request['phone']?.toString() ?? ''),
            if (introduction.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow('소속 소개', introduction),
            ],
            if (status == 'rejected' && adminComment.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow('거절 사유', adminComment),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 60.0),
        child: MenuButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
