import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passtime/admin/payment_ai_criteria_dialog.dart';
import 'package:passtime/admin/send_payment_detail_screen.dart';
import 'package:passtime/widgets/admin_menu_button.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum _PaymentSortOption {
  nameAsc('이름순'),
  studentIdAsc('학번순'),
  pendingFirst('미승인 먼저'),
  approvedFirst('승인 먼저');

  const _PaymentSortOption(this.label);
  final String label;
}

class SendPaymentTicketListScreen extends StatefulWidget {
  final String ticketId;
  final String affiliationId;
  final String eventTitle;
  final String affiliationName;

  const SendPaymentTicketListScreen({
    super.key,
    required this.ticketId,
    required this.affiliationId,
    required this.eventTitle,
    this.affiliationName = '',
  });

  @override
  State<SendPaymentTicketListScreen> createState() =>
      _SendPaymentTicketListScreenState();
}

class _SendPaymentTicketListScreenState
    extends State<SendPaymentTicketListScreen> {
  final TextEditingController _searchController = TextEditingController();

  Map<String, bool> _switchValues = {};
  Map<String, Map<String, String>> _paymentData = {};
  Map<String, String> _aiReviewStatus = {};
  Map<String, List<String>> _aiReviewReasons = {};
  final Set<String> _selectedPaymentIds = {};
  bool _isLoading = true;
  bool _isBatchProcessing = false;
  bool _isAiReviewing = false;
  bool _isSelectionMode = false;
  PaymentAiCriteria? _aiCriteria;
  _PaymentSortOption _sortOption = _PaymentSortOption.nameAsc;

  int get _totalCount => _paymentData.length;

  int get _pendingCount =>
      _switchValues.values.where((approved) => !approved).length;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getCookieHeader() async {
    final baseUri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final cookies =
        await CookieJarSingleton().cookieJar.loadForRequest(baseUri);
    if (cookies.isEmpty) return '';
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _paymentData = {};
      _switchValues = {};
      _aiReviewStatus = {};
      _aiReviewReasons = {};
      _selectedPaymentIds.clear();
      _isSelectionMode = false;
    });

    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/payment/list?affiliationId=${widget.affiliationId}');

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.get(url, headers: {'Cookie': cookieHeader});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isSuccess'] == true && data['result'] != null) {
          final newPaymentData = <String, Map<String, String>>{};
          final newSwitchValues = <String, bool>{};
          final newAiReviewStatus = <String, String>{};
          final newAiReviewReasons = <String, List<String>>{};

          for (var payment in data['result']) {
            final paymentTicketId = payment['ticketId']?.toString();
            if (paymentTicketId != widget.ticketId) continue;

            final paymentId = payment['paymentId']?.toString();
            if (paymentId == null) continue;

            newPaymentData[paymentId] = {
              'name': payment['name']?.toString() ?? '이름 없음',
              'studentId': payment['studentId']?.toString() ?? '-',
              'major': payment['major']?.toString() ?? '-',
            };
            newSwitchValues[paymentId] =
                _readBool(payment['paymentPermissionStatus']);

            final aiStatus = payment['aiReviewStatus']?.toString() ?? 'none';
            newAiReviewStatus[paymentId] = aiStatus;
            if (aiStatus == 'suspicious' && payment['aiReviewReasons'] is List) {
              newAiReviewReasons[paymentId] = (payment['aiReviewReasons'] as List)
                  .map((e) => e.toString())
                  .toList();
            }
          }

          if (mounted) {
            setState(() {
              _paymentData = newPaymentData;
              _switchValues = newSwitchValues;
              _aiReviewStatus = newAiReviewStatus;
              _aiReviewReasons = newAiReviewReasons;
            });
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _filteredPaymentIds {
    final query = _searchController.text.trim().toLowerCase();
    var ids = _paymentData.keys.toList();

    if (query.isNotEmpty) {
      ids = ids.where((id) {
        final item = _paymentData[id]!;
        return item['name']!.toLowerCase().contains(query) ||
            item['studentId']!.toLowerCase().contains(query) ||
            item['major']!.toLowerCase().contains(query);
      }).toList();
    }

    ids.sort((a, b) {
      final itemA = _paymentData[a]!;
      final itemB = _paymentData[b]!;
      final approvedA = _switchValues[a] ?? false;
      final approvedB = _switchValues[b] ?? false;

      switch (_sortOption) {
        case _PaymentSortOption.nameAsc:
          return itemA['name']!.compareTo(itemB['name']!);
        case _PaymentSortOption.studentIdAsc:
          return itemA['studentId']!.compareTo(itemB['studentId']!);
        case _PaymentSortOption.pendingFirst:
          if (approvedA != approvedB) {
            return approvedA ? 1 : -1;
          }
          return itemA['name']!.compareTo(itemB['name']!);
        case _PaymentSortOption.approvedFirst:
          if (approvedA != approvedB) {
            return approvedA ? -1 : 1;
          }
          return itemA['name']!.compareTo(itemB['name']!);
      }
    });

    return ids;
  }

  void _toggleSelection(String paymentId) {
    setState(() {
      if (_selectedPaymentIds.contains(paymentId)) {
        _selectedPaymentIds.remove(paymentId);
      } else {
        _selectedPaymentIds.add(paymentId);
      }
    });
  }

  void _enterSelectionMode({String? paymentId}) {
    setState(() {
      _isSelectionMode = true;
      if (paymentId != null) {
        _selectedPaymentIds.add(paymentId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPaymentIds.clear();
    });
  }

  void _toggleSelectionMode() {
    if (_isSelectionMode) {
      _exitSelectionMode();
    } else {
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  void _toggleSelectAllFiltered(List<String> filteredIds) {
    setState(() {
      final allSelected = filteredIds.isNotEmpty &&
          filteredIds.every(_selectedPaymentIds.contains);
      if (allSelected) {
        _selectedPaymentIds.removeAll(filteredIds);
      } else {
        _selectedPaymentIds.addAll(filteredIds);
      }
    });
  }

  Future<bool> _updatePaymentStatus({
    required String paymentId,
    required bool approve,
  }) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String apiUrl =
        approve ? "$baseUrl/payment/permission" : "$baseUrl/payment/deny";
    final uri = Uri.parse("$apiUrl?paymentId=$paymentId");

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.put(
        uri,
        headers: {'Cookie': cookieHeader},
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['isSuccess'] == true) {
        if (mounted) {
          setState(() {
            _switchValues[paymentId] = approve;
          });
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleApproval({
    required String paymentId,
    required bool newValue,
  }) async {
    final previous = _switchValues[paymentId] ?? false;
    setState(() {
      _switchValues[paymentId] = newValue;
    });

    final success =
        await _updatePaymentStatus(paymentId: paymentId, approve: newValue);
    if (!success && mounted) {
      setState(() {
        _switchValues[paymentId] = previous;
      });
      _showErrorDialog('처리에 실패했습니다.');
    }
  }

  Future<void> _batchProcess({required bool approve}) async {
    if (_selectedPaymentIds.isEmpty || _isBatchProcessing) return;

    final actionLabel = approve ? '승인' : '미승인';
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('일괄 $actionLabel'),
        content: Text(
          '선택한 ${_selectedPaymentIds.length}명을 $actionLabel 처리하시겠습니까?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: Text('확인',
                style: TextStyle(color: approve
                    ? const Color(0xFF334D61)
                    : const Color(0xFFC10230))),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isBatchProcessing = true;
    });

    final targets = _selectedPaymentIds.toList();
    var successCount = 0;
    var failCount = 0;

    for (final paymentId in targets) {
      final current = _switchValues[paymentId] ?? false;
      if (current == approve) {
        successCount++;
        continue;
      }

      final success =
          await _updatePaymentStatus(paymentId: paymentId, approve: approve);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (!mounted) return;

    setState(() {
      _isBatchProcessing = false;
      _selectedPaymentIds.clear();
      _isSelectionMode = false;
    });

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('일괄 $actionLabel 완료'),
        content: Text(
          failCount > 0
              ? '$successCount명 처리됨 · $failCount명 실패'
              : '$successCount명이 처리되었습니다.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인',
                style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  bool _readBool(dynamic value) {
    if (value == true) return true;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  void _applyAiReviewResult(Map<String, dynamic> result) {
    final paymentId = result['paymentId']?.toString();
    if (paymentId == null || !_paymentData.containsKey(paymentId)) return;

    final status = result['aiReviewStatus']?.toString() ?? 'none';
    _aiReviewStatus[paymentId] = status;

    final isApproved = _readBool(result['paymentPermissionStatus']) ||
        _readBool(result['autoApproved']) ||
        status == 'auto_approved';
    if (isApproved) {
      _switchValues[paymentId] = true;
    }

    if (status == 'suspicious') {
      final reasons = result['evaluation']?['reasons'] ??
          result['aiReview']?['reasons'];
      if (reasons is List) {
        _aiReviewReasons[paymentId] =
            reasons.map((e) => e.toString()).toList();
      }
    } else {
      _aiReviewReasons.remove(paymentId);
    }
  }

  Future<void> _refreshPaymentStates() async {
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/payment/list?affiliationId=${widget.affiliationId}');

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.get(url, headers: {'Cookie': cookieHeader});

      if (response.statusCode != 200 || !mounted) return;

      final data = json.decode(response.body);
      if (data['isSuccess'] != true || data['result'] == null) return;

      setState(() {
        for (final payment in data['result']) {
          if (payment is! Map) continue;

          final paymentTicketId = payment['ticketId']?.toString();
          if (paymentTicketId != widget.ticketId) continue;

          final paymentId = payment['paymentId']?.toString();
          if (paymentId == null || !_paymentData.containsKey(paymentId)) {
            continue;
          }

          _switchValues[paymentId] =
              _readBool(payment['paymentPermissionStatus']);

          final aiStatus = payment['aiReviewStatus']?.toString() ?? 'none';
          _aiReviewStatus[paymentId] = aiStatus;

          if (aiStatus == 'suspicious' && payment['aiReviewReasons'] is List) {
            _aiReviewReasons[paymentId] =
                (payment['aiReviewReasons'] as List)
                    .map((e) => e.toString())
                    .toList();
          } else {
            _aiReviewReasons.remove(paymentId);
          }
        }
      });
    } catch (_) {
      // 배치 응답 반영이 우선이므로 조용히 무시
    }
  }

  Future<void> _runAiBatchReview() async {
    if (_isAiReviewing || _isBatchProcessing) return;

    final criteria = await showPaymentAiCriteriaDialog(
      context,
      initial: _aiCriteria,
    );
    if (criteria == null || !mounted) return;

    setState(() {
      _aiCriteria = criteria;
      _isAiReviewing = true;
    });

    final url =
        Uri.parse('${dotenv.env['API_BASE_URL']}/payment/ai-review/batch');

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookieHeader,
        },
        body: json.encode({
          'affiliationId': widget.affiliationId,
          'ticketId': widget.ticketId,
          'criteria': criteria.toJson(),
          'autoApprove': true,
        }),
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['isSuccess'] == true) {
        final result = data['result'] as Map<String, dynamic>? ?? {};
        final results = result['results'] as List<dynamic>? ?? [];

        setState(() {
          for (final item in results) {
            if (item is Map) {
              _applyAiReviewResult(Map<String, dynamic>.from(item));
            }
          }
        });

        await _refreshPaymentStates();

        if (!mounted) return;

        final totalTargets = result['totalTargets'] ?? 0;
        final reviewedCount = result['reviewedCount'] ?? 0;
        final autoApprovedCount = result['autoApprovedCount'] ?? 0;
        final suspiciousCount = result['suspiciousCount'] ?? 0;
        final failedCount = result['failedCount'] ?? 0;

        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('BETA AI 판별 완료'),
              content: Text(
                '검토 대상 $totalTargets건\n'
                '검토 완료 $reviewedCount건 · 실패 $failedCount건\n'
                '자동 승인 $autoApprovedCount건 · 의심 $suspiciousCount건',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '확인',
                    style: TextStyle(color: Color(0xFFC10230)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        _showErrorDialog(
          data['message']?.toString() ?? 'AI 판별 요청에 실패했습니다.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showErrorDialog('AI 판별 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiReviewing = false;
        });
      }
    }
  }

  Widget _buildAiReviewBadge(String paymentId) {
    final status = _aiReviewStatus[paymentId] ?? 'none';

    if (status == 'none') {
      return const SizedBox.shrink();
    }

    if (status == 'reviewing') {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    late final String label;
    late final Color backgroundColor;
    late final Color textColor;
    late final double fontSize;
    late final EdgeInsets padding;

    switch (status) {
      case 'auto_approved':
        label = '자동승인';
        backgroundColor = const Color(0xFF334D61);
        textColor = Colors.white;
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
      case 'suspicious':
        label = '의심';
        backgroundColor = const Color(0xFFFFE082);
        textColor = const Color(0xFF8D6E00);
        fontSize = 11;
        padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 3);
        break;
      case 'failed':
        label = '검토실패';
        backgroundColor = const Color(0xFFC10230).withOpacity(0.15);
        textColor = const Color(0xFFC10230);
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildAiReviewButton() {
    return Material(
      color: const Color(0xFF334D61).withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap:
            _isAiReviewing || _isBatchProcessing ? null : _runAiBatchReview,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAiReviewing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC10230),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'BETA',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                _isAiReviewing ? '판별 중' : 'AI 판별',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334D61),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectAndSortButtons(bool hasData) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: _isSelectionMode
              ? const Color(0xFF334D61).withOpacity(0.15)
              : const Color(0xFF334D61).withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: hasData ? _toggleSelectionMode : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    _isSelectionMode ? '취소' : '다중 선택',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isSelectionMode
                          ? const Color(0xFFC10230)
                          : const Color(0xFF334D61),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFF334D61).withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: _showSortSheet,
            borderRadius: BorderRadius.circular(4),
            child: const SizedBox(
              height: 40,
              width: 40,
              child: Icon(
                Icons.sort_rounded,
                color: Color(0xFF334D61),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '정렬',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._PaymentSortOption.values.map((option) {
                final isSelected = _sortOption == option;
                return ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFC10230)
                          : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFFC10230))
                      : null,
                  onTap: () {
                    setState(() {
                      _sortOption = option;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredIds = _filteredPaymentIds;
    final hasData = _paymentData.isNotEmpty;
    final allFilteredSelected = filteredIds.isNotEmpty &&
        filteredIds.every(_selectedPaymentIds.contains);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            _isSelectionMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: _isSelectionMode ? 26 : 22,
          ),
          onPressed: () {
            if (_isSelectionMode) {
              _exitSelectionMode();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isSelectionMode
              ? '${_selectedPaymentIds.length}명 선택'
              : '납부자 명단',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasData && filteredIds.isNotEmpty && _isSelectionMode)
            TextButton(
              onPressed: _isBatchProcessing
                  ? null
                  : () => _toggleSelectAllFiltered(filteredIds),
              child: Text(
                allFilteredSelected ? '선택 해제' : '전체 선택',
                style: const TextStyle(
                  color: Color(0xFF334D61),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 2,
            thickness: 2,
            color: const Color(0xFF334D61).withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334D61),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '주최 소속  ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.affiliationName.isNotEmpty
                            ? widget.affiliationName
                            : '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                if (hasData)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 8),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '총 $_totalCount명',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.45),
                                ),
                              ),
                              TextSpan(
                                text: '  ·  ',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.25),
                                ),
                              ),
                              TextSpan(
                                text: '승인 대기 $_pendingCount명',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _pendingCount > 0
                                      ? const Color(0xFFC10230)
                                      : Colors.black.withOpacity(0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildAiReviewButton(),
                      ),
                    ],
                  ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334D61).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '이름, 학번, 전공 검색',
                            hintStyle: TextStyle(
                              color: Colors.black.withOpacity(0.3),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black.withOpacity(0.35),
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.black.withOpacity(0.35),
                                    ),
                                    onPressed: _searchController.clear,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    _buildMultiSelectAndSortButtons(hasData),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasData
                    ? Align(
                        alignment: const Alignment(0.0, -0.15),
                        child: Text(
                          '납부 내역이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF334D61).withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : filteredIds.isEmpty
                        ? Align(
                            alignment: const Alignment(0.0, -0.15),
                            child: Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    const Color(0xFF334D61).withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.black,
                            backgroundColor: Colors.white,
                            onRefresh: _fetchPayments,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                _isSelectionMode ? 88 : 16,
                              ),
                              itemCount: filteredIds.length,
                              itemBuilder: (context, index) {
                                return _buildListItem(filteredIds[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: !_isSelectionMode
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF334D61).withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedPaymentIds.length}명 선택',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334D61),
                      ),
                    ),
                    const Spacer(),
                    if (_isBatchProcessing)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      TextButton(
                        onPressed: _selectedPaymentIds.isEmpty || _isBatchProcessing
                            ? null
                            : () => _batchProcess(approve: false),
                        child: const Text(
                          '일괄 미승인',
                          style: TextStyle(
                            color: Color(0xFFC10230),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: _selectedPaymentIds.isEmpty || _isBatchProcessing
                            ? null
                            : () => _batchProcess(approve: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334D61),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          '일괄 승인',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : const AdminMenuButton(),
    );
  }

  Widget _buildListItem(String paymentId) {
    final name = _paymentData[paymentId]?['name'] ?? '이름 없음';
    final studentId = _paymentData[paymentId]?['studentId'] ?? '-';
    final major = _paymentData[paymentId]?['major'] ?? '-';
    final isApproved = _switchValues[paymentId] ?? false;
    final isSelected = _selectedPaymentIds.contains(paymentId);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF334D61).withOpacity(0.12)
            : const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(color: const Color(0xFF334D61).withOpacity(0.35))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: _isBatchProcessing
                  ? null
                  : () => _enterSelectionMode(paymentId: paymentId),
              onTap: () {
                if (_isSelectionMode) {
                  if (!_isBatchProcessing) {
                    _toggleSelection(paymentId);
                  }
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SendPaymentDetailScreen(paymentId: paymentId),
                  ),
                ).then((changed) {
                  if (changed == true && mounted) {
                    _fetchPayments();
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$studentId · $major',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAiReviewBadge(paymentId),
              if ((_aiReviewStatus[paymentId] ?? 'none') != 'none')
                const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.72,
                    child: CupertinoSwitch(
                      value: isApproved,
                      activeTrackColor: const Color(0xFF334D61),
                      onChanged: _isBatchProcessing
                          ? null
                          : (bool value) {
                              _toggleApproval(
                                paymentId: paymentId,
                                newValue: value,
                              );
                            },
                    ),
                  ),
                  Text(
                    isApproved ? '승인' : '대기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isApproved
                          ? const Color(0xFF334D61)
                          : const Color(0xFFC10230),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
