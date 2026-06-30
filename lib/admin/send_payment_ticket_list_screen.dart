import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passtime/admin/send_payment_detail_screen.dart';
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
  final Set<String> _selectedPaymentIds = {};
  bool _isLoading = true;
  bool _isBatchProcessing = false;
  bool _isSelectionMode = false;
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
                payment['paymentPermissionStatus'] as bool? ?? false;
          }

          if (mounted) {
            setState(() {
              _paymentData = newPaymentData;
              _switchValues = newSwitchValues;
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
          if (hasData)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
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
            ),
          ),
          const SizedBox(height: 8),
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
                );
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
    );
  }
}
