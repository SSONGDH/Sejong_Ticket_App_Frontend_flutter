import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:passtime/widgets/app_bar.dart';

class RequestRefundDetailScreen extends StatefulWidget {
  final String refundId;

  const RequestRefundDetailScreen({super.key, required this.refundId});

  @override
  State<RequestRefundDetailScreen> createState() =>
      _RequestRefundDetailScreenState();
}

class _RequestRefundDetailScreenState extends State<RequestRefundDetailScreen> {
  late Future<Map<String, dynamic>> refundDetail;

  @override
  void initState() {
    super.initState();
    refundDetail = fetchRefundDetail();
  }

  Future<Map<String, dynamic>> fetchRefundDetail() async {
    final String apiUrl = "${dotenv.env['API_BASE_URL']}/refund/refundDetail";
    final response = await http.get(
      Uri.parse("$apiUrl?refundId=${widget.refundId}"),
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

  Future<void> _updateRefundStatus(bool approve) async {
    final String apiUrl = approve
        ? "${dotenv.env['API_BASE_URL']}/refund/refundPermission"
        : "${dotenv.env['API_BASE_URL']}/refund/refundDeny";
    final uri = Uri.parse("$apiUrl?refundId=${widget.refundId}");

    try {
      final response = await http.put(uri);
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody["isSuccess"] == true) {
        setState(() {
          refundDetail = fetchRefundDetail(); // 상태 새로고침
        });

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(approve ? "승인 완료" : "미승인 처리 완료"),
              content: Text(
                approve ? "환불 요청이 승인되었습니다." : "환불 요청이 미승인 처리되었습니다.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 알림창 닫기
                    Navigator.of(context).pop(true); // 이전 화면으로 true 전달
                  },
                  child: const Text("확인"),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(responseBody["message"] ?? "처리에 실패했습니다.");
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("오류"),
            content: Text("상태 변경 중 오류 발생: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "환불 신청 상세화면",
        backgroundColor: Color(0xFF282727),
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
          final isApproved = data["refundPermissionStatus"] == true;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("이름", data["name"]),
                _buildDetailRow("학번", data["studentId"]),
                _buildDetailRow("전화번호", data["phone"]),
                _buildDetailRow("행사", data["eventTitle"]),
                _buildDetailRow("환불 사유", data["refundReason"]),
                _buildDetailRow("방문 가능 날짜", data["visitDate"]),
                _buildDetailRow("방문 가능 시간", data["visitTime"]),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateRefundStatus(!isApproved),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF282727),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isApproved ? "미승인" : "승인",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
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
