import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RefundScreen extends StatefulWidget {
  final String ticketId;

  const RefundScreen({super.key, required this.ticketId});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  late Future<Map<String, dynamic>> refundDetail;

  @override
  void initState() {
    super.initState();
    refundDetail = fetchRefundDetail();
  }

  Future<Map<String, dynamic>> fetchRefundDetail() async {
    final String apiUrl = "${dotenv.env['API_BASE_URL']}/ticketRefundDetail";
    final response = await http.get(
      Uri.parse("$apiUrl?ticketId=${widget.ticketId}"),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody["isSuccess"] == true) {
        return responseBody["result"];
      } else {
        throw Exception("API 요청 실패: ${responseBody['message']}");
      }
    } else {
      throw Exception("서버 오류: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7), // 배경색 변경
      appBar: AppBar(
        // AppBar 스타일 변경
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF334D61),
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '환불 상세 내역', // 제목은 원래 제목 유지
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: refundDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("오류 발생: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("데이터 없음"));
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("이름", data["name"]),
                _buildDetailRow("학번", data["studentId"]),
                _buildDetailRow("행사", data["eventName"]),
                _buildDetailRow("환불 사유", data["refundReason"]),
                _buildDetailRow(
                    "방문 일시", "${data["visitDate"]} / ${data["visitTime"]}"),
                _buildDetailRow("환불 상태", data["refundPermissionStatus"]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.isNotEmpty ? value : "-",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
