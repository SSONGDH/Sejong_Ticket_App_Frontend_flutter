import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:passtime/cookiejar_singleton.dart';

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
    final cookieHeader = await _getCookieHeader();

    final response = await http.get(uri, headers: {'Cookie': cookieHeader});

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

  Future<String> _getCookieHeader() async {
    final baseUri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final cookies =
        await CookieJarSingleton().cookieJar.loadForRequest(baseUri);
    if (cookies.isEmpty) return '';
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  Future<void> approvePayment(String paymentId) async {
    if (isApproving) return;

    setState(() {
      isApproving = true;
    });

    final String apiUrl = "${dotenv.env['API_BASE_URL']}/payment/permission";
    final uri = Uri.parse("$apiUrl?paymentId=$paymentId");

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.put(
        uri,
        headers: {'Cookie': cookieHeader},
      );
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseBody["isSuccess"] == true &&
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
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("확인",
                      style: TextStyle(color: Color(0xFFC10230))),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(responseBody["message"] ?? "결제 승인에 실패했습니다. 다시 시도해주세요.");
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = (bottomInset > 0 ? bottomInset : 16).toDouble();

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
        body: FutureBuilder<Map<String, dynamic>>(
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
            final isApproved = data["paymentPermissionStatus"] == true;
            final aiReviewStatus =
                data["aiReviewStatus"]?.toString() ?? 'none';
            final aiReview = data["aiReview"] as Map<String, dynamic>?;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (aiReviewStatus != 'none')
                          _buildAiReviewSection(aiReviewStatus, aiReview),
                        _buildPaymentImage(data["paymentPicture"]),
                        const SizedBox(height: 32),
                        _buildInfoTile("이름", data["name"]),
                        _buildInfoTile("학번", data["studentId"]),
                        _buildInfoTile("전화번호", data["phone"]),
                        _buildInfoTile("행사", data["eventTitle"]),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: (isApproved || isApproving)
                          ? null
                          : () => approvePayment(widget.paymentId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApproved
                            ? const Color(0xFFC10230)
                            : const Color(0xFF334D61),
                        disabledBackgroundColor:
                            const Color(0xFF334D61).withOpacity(0.3),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withOpacity(0.7),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAiReviewSection(
    String status,
    Map<String, dynamic>? aiReview,
  ) {
    late final String title;
    late final Color backgroundColor;
    late final Color textColor;

    switch (status) {
      case 'auto_approved':
        title = 'AI 자동 승인';
        backgroundColor = const Color(0xFF334D61);
        textColor = Colors.white;
        break;
      case 'suspicious':
        title = 'AI 의심 — 관리자 확인 필요';
        backgroundColor = const Color(0xFFFFE082);
        textColor = const Color(0xFF8D6E00);
        break;
      case 'failed':
        title = 'AI 검토 실패';
        backgroundColor = const Color(0xFFC10230).withOpacity(0.15);
        textColor = const Color(0xFFC10230);
        break;
      case 'reviewing':
        title = 'AI 검토 중';
        backgroundColor = const Color(0xFF334D61).withOpacity(0.1);
        textColor = const Color(0xFF334D61);
        break;
      default:
        return const SizedBox.shrink();
    }

    final reasons = aiReview?['reasons'] as List<dynamic>? ?? [];
    final extractedAmount = aiReview?['extractedAmount'];
    final extractedDate = aiReview?['extractedDate'];
    final extractedSender = aiReview?['extractedSenderName'];
    final extractedAccount = aiReview?['extractedAccountHolderName'];
    final confidence = aiReview?['combinedConfidence'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          if (aiReview != null) ...[
            const SizedBox(height: 10),
            if (extractedAmount != null)
              _buildAiInfoRow('추출 금액', '$extractedAmount원', textColor),
            if (extractedDate != null)
              _buildAiInfoRow('추출 날짜', extractedDate.toString(), textColor),
            if (extractedSender != null)
              _buildAiInfoRow('보낸 사람', extractedSender.toString(), textColor),
            if (extractedAccount != null)
              _buildAiInfoRow(
                '받는 사람',
                extractedAccount.toString(),
                textColor,
              ),
            if (confidence != null)
              _buildAiInfoRow(
                '신뢰도',
                '${(confidence is num ? confidence * 100 : double.tryParse(confidence.toString()) ?? 0).toStringAsFixed(1)}%',
                textColor,
              ),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '사유',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '· $reason',
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.85),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
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
                fit: BoxFit.contain,
                width: 240,
                height: 240,
              ),
            )
          : Center(
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
