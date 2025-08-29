import 'package:flutter/material.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/admin/request_refund_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';
import 'package:PASSTIME/widgets/refund_ticket_card.dart';

class RequestRefundListScreen extends StatefulWidget {
  const RequestRefundListScreen({super.key});

  @override
  _RequestRefundListScreenState createState() =>
      _RequestRefundListScreenState();
}

class _RequestRefundListScreenState extends State<RequestRefundListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  List<Map<String, dynamic>> _affiliations = [];
  List<Map<String, dynamic>> _refundRequests = [];
  bool _isAffiliationLoading = true;
  bool _isRefundDataLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAffiliations();
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      final selectedAffiliationId = _affiliations[_tabController!.index]['id'];
      _fetchRefundData(affiliationId: selectedAffiliationId);
    }
  }

  Future<void> _fetchAffiliations() async {
    final url =
        Uri.parse('${dotenv.env['API_BASE_URL']}/user/adminAffilliation/list');
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await http.get(url, headers: {'Cookie': cookieHeader});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['affiliations'] != null) {
          List<Map<String, dynamic>> fetchedAffiliations =
              List<Map<String, dynamic>>.from(data['affiliations']);

          // [핵심 로직 1] '전체' 탭을 위한 가상 데이터를 리스트 가장 앞에 추가합니다.
          fetchedAffiliations.insert(0, {'id': null, 'name': '전체'});

          setState(() {
            _affiliations = fetchedAffiliations;
            _isAffiliationLoading = false;

            if (_affiliations.isNotEmpty) {
              _tabController =
                  TabController(length: _affiliations.length, vsync: this);
              _tabController!.addListener(_handleTabSelection);

              // 화면 첫 로딩 시 '전체' 목록을 불러오도록 affiliationId를 null로 전달합니다.
              _fetchRefundData(affiliationId: null);
            }
          });
        } else {
          setState(() {
            _isAffiliationLoading = false;
            _errorMessage = data['message'] ?? "소속 목록을 불러오는데 실패했습니다.";
          });
        }
      } else {
        setState(() {
          _isAffiliationLoading = false;
          _errorMessage = "서버 오류: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isAffiliationLoading = false;
        _errorMessage = "네트워크 오류: $e";
      });
    }
  }

  // [핵심 로직 2] affiliationId를 nullable(String?)로 변경하여 null 값을 받을 수 있게 합니다.
  Future<void> _fetchRefundData({String? affiliationId}) async {
    setState(() {
      _isRefundDataLoading = true;
      _refundRequests = []; // 데이터를 새로 불러오기 전에 기존 목록 초기화
    });

    // [핵심 로직 3] affiliationId가 null이면 쿼리 파라미터를 붙이지 않고, 값이 있으면 붙입니다.
    String urlString = '${dotenv.env['API_BASE_URL']}/refund/list';
    if (affiliationId != null) {
      urlString += '?affiliationId=$affiliationId';
    }
    final url = Uri.parse(urlString);
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await http.get(url, headers: {'Cookie': cookieHeader});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isSuccess'] == true && data['result'] != null) {
          final List<dynamic> result = data['result'];
          final List<Map<String, dynamic>> newRefundRequests =
              result.map((refund) {
            return {
              '_id': refund['_id'],
              'title': refund['eventName'],
              'studentInfo': '${refund['studentId']} • ${refund['name']}',
              'visitTime': '${refund['visitDate']} • ${refund['visitTime']}',
              'status':
                  refund['refundPermissionStatus'] == 'TRUE' ? '승인됨' : '미승인',
              'statusColor': refund['refundPermissionStatus'] == 'TRUE'
                  ? const Color(0xFF334D61)
                  : const Color(0xFFC10230),
              'refundReason': refund['refundReason'],
            };
          }).toList();
          setState(() {
            _refundRequests = newRefundRequests;
          });
        } else {
          setState(() {
            _refundRequests = [];
          });
        }
      }
    } catch (error) {
      // 에러 처리 (필요 시 _errorMessage 상태 변수 사용)
      print("Error fetching refund data: $error");
    } finally {
      setState(() {
        _isRefundDataLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "환불 신청 목록"),
      floatingActionButton: const AdminMenuButton(),
      body: _isAffiliationLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _affiliations.isEmpty
                  ? const Center(child: Text("관리 중인 소속이 없습니다."))
                  : Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            isScrollable: true,
                            controller: _tabController,
                            tabAlignment: TabAlignment.start,
                            tabs: _affiliations.map((affiliation) {
                              return Tab(text: affiliation['name']);
                            }).toList(),
                            labelColor: const Color(0xFFC10230),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFFC10230),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _affiliations.map((_) {
                              return _buildRefundList();
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildRefundList() {
    if (_isRefundDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_refundRequests.isEmpty) {
      return Align(
        alignment: const Alignment(0.0, -0.15),
        child: Text(
          '환불 신청 목록이 없습니다',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF334D61).withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: Colors.white,
      onRefresh: () async {
        if (_tabController != null) {
          final selectedAffiliationId =
              _affiliations[_tabController!.index]['id'];
          await _fetchRefundData(affiliationId: selectedAffiliationId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ListView.builder(
          itemCount: _refundRequests.length,
          itemBuilder: (context, index) {
            final refund = _refundRequests[index];
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 10.0 : 5.0),
              child: RefundTicketCard(
                title: refund['title']!,
                studentInfo: refund['studentInfo']!,
                visitTime: refund['visitTime']!,
                refundReason: refund['refundReason']!,
                status: refund['status']!,
                statusColor: refund['statusColor']!,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestRefundDetailScreen(refundId: refund['_id']),
                    ),
                  );
                  if (result == true && _tabController != null) {
                    final selectedAffiliationId =
                        _affiliations[_tabController!.index]['id'];
                    _fetchRefundData(affiliationId: selectedAffiliationId);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
