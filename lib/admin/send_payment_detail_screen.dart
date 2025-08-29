import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';

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
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: const Text("승인 완료"),
                content: const Text("결제 승인이 완료되었습니다."),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(true); // 이전 화면으로 true 전달
                    },
                    child: const Text("확인",
                        style: TextStyle(color: Color(0xFFC10230))),
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
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("오류"),
            content: Text("승인 중 오류 발생: $e"),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("확인",
                    style: TextStyle(color: Color(0xFFC10230))),
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
          children: [
            Divider(
              height: 2,
              thickness: 2,
              color: const Color(0xFF334D61).withOpacity(0.05),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildPaymentImage(data["paymentPicture"]),
                        const SizedBox(height: 32),
                        _buildInfoTile("이름", data["name"]),
                        _buildInfoTile("학번", data["studentId"]),
                        _buildInfoTile("전화번호", data["phone"]),
                        _buildInfoTile("행사", data["eventTitle"]),
                      ],
                    ),
                  );
                },
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: paymentDetail,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final data = snapshot.data!;
                final isApproved = data["paymentPermissionStatus"] == true;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                  child: SafeArea(
                    child: // SendPaymentDetailScreen.dart 파일의 하단 FutureBuilder 내부

                        ElevatedButton(
                      onPressed: (isApproved || isApproving)
                          ? null
                          : () => approvePayment(widget.paymentId),
                      style: ElevatedButton.styleFrom(
                        // 활성화 상태일 때의 색상
                        backgroundColor: const Color(0xFF334D61),
                        // ❗ 비활성화 상태일 때의 색상을 여기에 지정합니다.
                        disabledBackgroundColor:
                            const Color(0xFF334D61).withOpacity(0.3),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            Colors.white.withOpacity(0.7), // 비활성화 시 텍스트 색상
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
                              isApproved ? "승인됨" : "승인",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentImage(String? imageUrl) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 240,
                height: 240,
              ),
            )
          : Center(
              // Added Center for the text as well
              child: Text("납부내역 사진",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.5),
                      fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.isNotEmpty ? value : "-",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
