import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AffiliationRequest {
  final String id;
  final String name;
  final String studentId;
  final String phone;
  final String affiliationName;
  final bool requestAdmin;
  final bool createAffiliation;
  final String status;

  AffiliationRequest({
    required this.id,
    required this.name,
    required this.studentId,
    required this.phone,
    required this.affiliationName,
    required this.requestAdmin,
    required this.createAffiliation,
    required this.status,
  });

  factory AffiliationRequest.fromJson(Map<String, dynamic> json) {
    return AffiliationRequest(
      id: json['_id'],
      name: json['name'],
      studentId: json['studentId'],
      phone: json['phone'],
      affiliationName: json['affiliationName'],
      requestAdmin: json['requestAdmin'],
      createAffiliation: json['createAffiliation'],
      status: json['status'],
    );
  }
}

class RequestAdminDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestAdminDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<RequestAdminDetailScreen> createState() =>
      _RequestAdminDetailScreenState();
}

class _RequestAdminDetailScreenState extends State<RequestAdminDetailScreen> {
  Future<AffiliationRequest>? _requestDetailFuture;
  bool _isApproving = false;

  Future<String> _getAccessToken() async {
    return 'YOUR_ACCESS_TOKEN'; // TODO: 실제 액세스 토큰으로 교체!
  }

  @override
  void initState() {
    super.initState();
    _requestDetailFuture = _fetchRequestDetails();
  }

  Future<AffiliationRequest> _fetchRequestDetails() async {
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/affiliation/affiliationRequests/${widget.requestId}');
    final accessToken = await _getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    print('[GET] Requesting URL: $url');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return AffiliationRequest.fromJson(data['result']);
      } else {
        print('[GET] Error Status Code: ${response.statusCode}');
        print('[GET] Error Response Body: ${utf8.decode(response.bodyBytes)}');
        throw Exception('상세 정보를 불러오는데 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('[GET] Exception: $e');
      throw Exception('오류가 발생했습니다: $e');
    }
  }

  // [수정 1] 승인 요청 전 확인 팝업을 띄우는 함수
  void _showApprovalConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("승인 확인"),
        content: const Text("이 신청을 승인하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("확인", style: TextStyle(color: Color(0xFFC10230))),
            onPressed: () {
              Navigator.pop(context); // 확인 팝업 닫기
              _approveRequest(); // 승인 함수 호출
            },
          ),
        ],
      ),
    );
  }

  // [수정 2] SnackBar를 CupertinoAlertDialog로 변경
  Future<void> _approveRequest() async {
    if (_isApproving) return;
    setState(() {
      _isApproving = true;
    });
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/affiliation/approve?requestId=${widget.requestId}');
    final accessToken = await _getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    print('[POST] Requesting URL: $url');

    try {
      final response = await http.post(url, headers: headers);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공 팝업
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('승인 완료'),
            content: const Text('성공적으로 승인되었습니다.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('확인',
                    style: TextStyle(color: Color(0xFFC10230))),
                onPressed: () {
                  Navigator.pop(dialogContext); // 팝업 닫기
                  Navigator.pop(context, true); // 이전 화면으로 이동
                },
              ),
            ],
          ),
        );
      } else {
        // 실패 팝업
        print('[POST] Error Status Code: ${response.statusCode}');
        print('[POST] Error Response Body: ${utf8.decode(response.bodyBytes)}');
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('승인 실패'),
            content: Text(errorData['message'] ?? '알 수 없는 오류가 발생했습니다.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('확인',
                    style: TextStyle(color: Color(0xFFC10230))),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('[POST] Exception: $e');
      if (!mounted) return;
      // 네트워크 오류 등 예외 팝업
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('오류 발생'),
          content: Text('요청 중 오류가 발생했습니다: $e'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child:
                  const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
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
              child: FutureBuilder<AffiliationRequest>(
                future: _requestDetailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('오류: ${snapshot.error}',
                          textAlign: TextAlign.center),
                    ));
                  } else if (snapshot.hasData) {
                    final detail = snapshot.data!;
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoContainer(
                                    label: "이름", value: detail.name),
                                const SizedBox(height: 16),
                                _buildInfoContainer(
                                    label: "학번", value: detail.studentId),
                                const SizedBox(height: 16),
                                _buildInfoContainer(
                                    label: "전화번호", value: detail.phone),
                                const SizedBox(height: 16),
                                _buildInfoContainer(
                                    label: "소속", value: detail.affiliationName),
                                const SizedBox(height: 16),
                                _buildInfoContainer(
                                    label: "생성 요청",
                                    value:
                                        detail.createAffiliation ? "예" : "아니오"),
                                const SizedBox(height: 16),
                                _buildInfoContainer(
                                    label: "권한 요청",
                                    value: detail.requestAdmin ? "예" : "아니오"),
                              ],
                            ),
                          ),
                        ),
                        _buildBottomButton(detail),
                      ],
                    );
                  } else {
                    return const Center(child: Text('데이터가 없습니다.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(AffiliationRequest detail) {
    final bool isApproved = detail.status == 'approved';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
      child: SafeArea(
        child: ElevatedButton(
          // [수정 3] onPressed가 확인 팝업을 띄우도록 변경
          onPressed: isApproved || _isApproving
              ? null
              : _showApprovalConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF334D61),
            disabledBackgroundColor: const Color(0xFF334D61).withOpacity(0.3),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withOpacity(0.7),
          ),
          child: _isApproving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  isApproved ? "승인 완료" : "승인",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
              textAlign: TextAlign.start,
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
