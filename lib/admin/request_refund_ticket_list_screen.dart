import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passtime/admin/request_refund_detail_screen.dart';
import 'package:passtime/widgets/admin_menu_button.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestRefundTicketListScreen extends StatefulWidget {
  final String ticketId;
  final String affiliationId;
  final String eventTitle;
  final String affiliationName;

  const RequestRefundTicketListScreen({
    super.key,
    required this.ticketId,
    required this.affiliationId,
    required this.eventTitle,
    this.affiliationName = '',
  });

  @override
  State<RequestRefundTicketListScreen> createState() =>
      _RequestRefundTicketListScreenState();
}

class _RequestRefundTicketListScreenState
    extends State<RequestRefundTicketListScreen> {
  final TextEditingController _searchController = TextEditingController();

  Map<String, bool> _switchValues = {};
  Map<String, Map<String, String>> _refundData = {};
  bool _isLoading = true;

  int get _totalCount => _refundData.length;

  int get _pendingCount =>
      _switchValues.values.where((approved) => !approved).length;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchRefunds();
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

  bool _readApproved(dynamic status) {
    if (status == true || status == 'TRUE') return true;
    if (status is String && status.toUpperCase() == 'TRUE') return true;
    return false;
  }

  Future<void> _fetchRefunds() async {
    setState(() {
      _isLoading = true;
      _refundData = {};
      _switchValues = {};
    });

    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/refund/list?affiliationId=${widget.affiliationId}');

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.get(url, headers: {'Cookie': cookieHeader});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isSuccess'] == true && data['result'] != null) {
          final newRefundData = <String, Map<String, String>>{};
          final newSwitchValues = <String, bool>{};

          for (final refund in data['result']) {
            if (refund is! Map) continue;

            final refundTicketId = refund['ticketId']?.toString() ?? '';
            final eventName = refund['eventName']?.toString() ?? '';
            final matchesTicket = refundTicketId.isNotEmpty
                ? refundTicketId == widget.ticketId
                : eventName == widget.eventTitle;
            if (!matchesTicket) continue;

            final refundId = refund['_id']?.toString();
            if (refundId == null) continue;

            newRefundData[refundId] = {
              'name': refund['name']?.toString() ?? '이름 없음',
              'studentId': refund['studentId']?.toString() ?? '-',
              'visitTime':
                  '${refund['visitDate'] ?? '-'} · ${refund['visitTime'] ?? '-'}',
            };
            newSwitchValues[refundId] =
                _readApproved(refund['refundPermissionStatus']);
          }

          if (mounted) {
            setState(() {
              _refundData = newRefundData;
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

  List<String> get _filteredRefundIds {
    final query = _searchController.text.trim().toLowerCase();
    var ids = _refundData.keys.toList();

    if (query.isNotEmpty) {
      ids = ids.where((id) {
        final item = _refundData[id]!;
        return item['name']!.toLowerCase().contains(query) ||
            item['studentId']!.toLowerCase().contains(query) ||
            item['visitTime']!.toLowerCase().contains(query);
      }).toList();
    }

    ids.sort((a, b) {
      final itemA = _refundData[a]!;
      final itemB = _refundData[b]!;
      return itemA['name']!.compareTo(itemB['name']!);
    });

    return ids;
  }

  Future<bool> _updateRefundStatus({
    required String refundId,
    required bool approve,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final apiUrl =
        approve ? '$baseUrl/refund/permission' : '$baseUrl/refund/deny';
    final uri = Uri.parse('$apiUrl?refundId=$refundId');

    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.put(
        uri,
        headers: {'Cookie': cookieHeader},
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['isSuccess'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleApproval({
    required String refundId,
    required bool newValue,
  }) async {
    final previous = _switchValues[refundId] ?? false;
    setState(() {
      _switchValues[refundId] = newValue;
    });

    final success =
        await _updateRefundStatus(refundId: refundId, approve: newValue);
    if (!success && mounted) {
      setState(() {
        _switchValues[refundId] = previous;
      });
      _showErrorDialog('처리에 실패했습니다.');
    }
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

  @override
  Widget build(BuildContext context) {
    final filteredIds = _filteredRefundIds;
    final hasData = _refundData.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '환불 신청자 명단',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
                  hintText: '이름, 학번, 방문 시간 검색',
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
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
                          '환불 신청 내역이 없습니다',
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
                            onRefresh: _fetchRefunds,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filteredIds.length,
                              itemBuilder: (context, index) {
                                return _buildListItem(filteredIds[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: const AdminMenuButton(),
    );
  }

  Widget _buildListItem(String refundId) {
    final name = _refundData[refundId]?['name'] ?? '이름 없음';
    final studentId = _refundData[refundId]?['studentId'] ?? '-';
    final visitTime = _refundData[refundId]?['visitTime'] ?? '-';
    final isApproved = _switchValues[refundId] ?? false;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RequestRefundDetailScreen(refundId: refundId),
                  ),
                ).then((changed) {
                  if (changed == true && mounted) {
                    _fetchRefunds();
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
                    '$studentId · $visitTime',
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
                  onChanged: (bool value) {
                    _toggleApproval(
                      refundId: refundId,
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
