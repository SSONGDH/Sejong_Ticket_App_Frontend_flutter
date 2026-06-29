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
  final String requestType;
  final String requestTypeLabel;
  final String introduction;
  final String status;
  final String statusLabel;

  AffiliationRequest({
    required this.id,
    required this.name,
    required this.studentId,
    required this.phone,
    required this.affiliationName,
    required this.requestType,
    required this.requestTypeLabel,
    required this.introduction,
    required this.status,
    required this.statusLabel,
  });

  factory AffiliationRequest.fromJson(Map<String, dynamic> json) {
    final requestType = json['requestType']?.toString() ??
        (json['createAffiliation'] == true ? 'create' : 'admin');

    return AffiliationRequest(
      id: (json['requestId'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      affiliationName: json['affiliationName']?.toString() ?? '',
      requestType: requestType,
      requestTypeLabel: json['requestTypeLabel']?.toString() ??
          (requestType == 'create' ? '소속 생성' : '주최자 권한'),
      introduction: json['introduction']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['statusLabel']?.toString() ?? '',
    );
  }

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
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

  @override
  void initState() {
    super.initState();
    _requestDetailFuture = _fetchRequestDetails();
  }

  Future<AffiliationRequest> _fetchRequestDetails() async {
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/affiliation/affiliationRequests/${widget.requestId}');
    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return AffiliationRequest.fromJson(
          Map<String, dynamic>.from(data['result'] as Map),
        );
      } else {
        throw Exception('상세 정보를 불러오는데 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('오류가 발생했습니다: $e');
    }
  }

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
              Navigator.pop(context);
              _approveRequest();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest() async {
    if (_isApproving) return;
    setState(() {
      _isApproving = true;
    });
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/affiliation/approve?requestId=${widget.requestId}');
    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(url, headers: headers);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('승인 완료'),
            content: const Text('성공적으로 승인되었습니다.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인',
                    style: TextStyle(color: Color(0xFFC10230))),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        );
      } else {
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
      if (!mounted) return;
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
            Divider(
              height: 2,
              thickness: 2,
              color: const Color(0xFF334D61).withOpacity(0.05),
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
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoContainer(
                                    label: "신청 유형",
                                    value: detail.requestTypeLabel),
                                const SizedBox(height: 16),
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
                                if (detail.introduction.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildInfoContainer(
                                    label: "소속 소개",
                                    value: detail.introduction,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _buildInfoContainer(
                                  label: "상태",
                                  value: detail.statusLabel.isNotEmpty
                                      ? detail.statusLabel
                                      : detail.status,
                                ),
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final String buttonText = detail.isApproved
        ? '승인됨'
        : detail.isRejected
            ? '거절됨'
            : '승인';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 16 : 0),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: detail.isApproved ||
                  detail.isRejected ||
                  _isApproving
              ? null
              : _showApprovalConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF334D61),
            disabledBackgroundColor: const Color(0xFF334D61).withOpacity(0.3),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
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
                  buttonText,
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
