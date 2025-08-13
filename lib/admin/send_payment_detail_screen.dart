import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendPaymentDetailScreen extends StatefulWidget {
  final String paymentId;

  const SendPaymentDetailScreen({super.key, required this.paymentId});

  @override
  State<SendPaymentDetailScreen> createState() =>
      _SendPaymentDetailScreenState();
}

class _SendPaymentDetailScreenState extends State<SendPaymentDetailScreen> {
  late Future<Map<String, dynamic>> paymentDetail;
  bool isApproving = false;

  @override
  void initState() {
    super.initState();
    paymentDetail = fetchPaymentDetail();
  }

  Future<Map<String, dynamic>> fetchPaymentDetail() async {
    final String apiUrl = "${dotenv.env['API_BASE_URL']}/payment/detail";
    final uri = Uri.parse("$apiUrl?paymentId=${widget.paymentId}");

    print("[FETCH] GET $uri"); // 🔍 요청 URI 출력

    final response = await http.get(uri);

    print(
        "[FETCH] Response: ${response.statusCode} - ${response.body}"); // 🔍 응답 출력

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

  Future<void> approvePayment(String paymentId) async {
    setState(() {
      isApproving = true;
    });

    final String apiUrl = "${dotenv.env['API_BASE_URL']}/payment/permission";
    final uri = Uri.parse("$apiUrl?paymentId=$paymentId");

    print("[APPROVE] PUT $uri"); // 🔍 승인 요청 URI 출력

    try {
      final response = await http.put(uri);

      print(
          "[APPROVE] Response: ${response.statusCode} - ${response.body}"); // 🔍 응답 출력

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody["isSuccess"] == true &&
            responseBody["result"]["paymentPermissionStatus"] == true) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("승인 완료"),
                content: const Text("결제 승인이 완료되었습니다."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(true); // 이전 화면으로 true 전달
                    },
                    child: const Text("확인"),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception(
              responseBody["message"] ?? "결제 승인에 실패했습니다. 다시 시도해주세요.");
        }
      } else {
        throw Exception("서버 오류: ${response.statusCode}");
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("오류"),
            content: Text("승인 중 오류 발생: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isApproving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // AppBar 스타일 변경
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '납부 내역 상세',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        // Column으로 감싸서 Divider 추가
        children: [
          const Divider(
            // Divider 추가
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEDE3),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: paymentDetail,
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
                      const SizedBox(height: 20),
                      _buildPaymentImage(data["paymentPicture"]),
                      const SizedBox(height: 30),
                      _buildInfoTile("이름", data["name"]),
                      _buildInfoTile("학번", data["studentId"]),
                      _buildInfoTile("전화번호", data["phone"]),
                      _buildInfoTile("행사", data["eventTitle"]),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (data["paymentPermissionStatus"] == true ||
                                  isApproving)
                              ? null
                              : () => approvePayment(widget.paymentId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF282727),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isApproving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  data["paymentPermissionStatus"] == true
                                      ? "승인 완료"
                                      : "승인",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
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
    );
  }

  Widget _buildPaymentImage(String? imageUrl) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : const Text("납부내역 사진", style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildInfoTile(String label, String value) {
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
