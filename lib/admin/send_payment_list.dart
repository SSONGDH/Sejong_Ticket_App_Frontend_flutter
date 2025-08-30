import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'send_payment_detail_screen.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/admin_menu_button.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';

class SendPaymentListScreen extends StatefulWidget {
  const SendPaymentListScreen({super.key});

  @override
  _SendPaymentListScreenState createState() => _SendPaymentListScreenState();
}

class _SendPaymentListScreenState extends State<SendPaymentListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  List<Map<String, dynamic>> _affiliations = [];
  Map<String, bool> _switchValues = {};
  Map<String, Map<String, String>> _paymentData = {};
  bool _isAffiliationLoading = true;
  bool _isPaymentLoading = true;
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
      final selectedAffiliationId =
          _affiliations[_tabController!.index]['_id'] as String;
      _fetchPaymentData(affiliationId: selectedAffiliationId);
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

          setState(() {
            _affiliations = fetchedAffiliations;
            _isAffiliationLoading = false;

            if (_affiliations.isNotEmpty) {
              _tabController =
                  TabController(length: _affiliations.length, vsync: this);
              _tabController!.addListener(_handleTabSelection);

              final firstAffiliationId = _affiliations.first['_id'] as String;
              _fetchPaymentData(affiliationId: firstAffiliationId);
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

  Future<void> _fetchPaymentData({required String affiliationId}) async {
    setState(() {
      _isPaymentLoading = true;
      _paymentData = {};
      _switchValues = {};
    });

    String urlString =
        '${dotenv.env['API_BASE_URL']}/payment/list?affiliationId=$affiliationId';

    print("Request URL: $urlString");

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
          final newPaymentData = <String, Map<String, String>>{};
          final newSwitchValues = <String, bool>{};

          for (var payment in data['result']) {
            final studentId = payment['studentId']?.toString() ?? 'ID 없음';
            final name = payment['name']?.toString() ?? '이름 없음';
            final paymentId = payment['paymentId']?.toString();

            if (paymentId != null) {
              newPaymentData[paymentId] = {
                'name': name,
                'studentId': studentId,
              };
              newSwitchValues[paymentId] =
                  payment['paymentPermissionStatus'] as bool? ?? false;
            }
          }
          setState(() {
            _paymentData = newPaymentData;
            _switchValues = newSwitchValues;
          });
        }
      }
    } catch (error) {
      // 에러 처리
    } finally {
      setState(() {
        _isPaymentLoading = false;
      });
    }
  }

  Future<void> _toggleApproval({
    required String paymentId,
    required bool newValue,
  }) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String apiUrl =
        newValue ? "$baseUrl/payment/permission" : "$baseUrl/payment/deny";
    final uri = Uri.parse("$apiUrl?paymentId=$paymentId");
    final baseUri = Uri.parse(baseUrl);

    try {
      final cookies =
          await CookieJarSingleton().cookieJar.loadForRequest(baseUri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await http.put(
        uri,
        headers: {
          'Cookie': cookieHeader,
        },
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["isSuccess"] == true) {
        setState(() {
          _switchValues[paymentId] = newValue;
        });

        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: Text(newValue ? "승인 완료" : "미승인 완료"),
              content:
                  Text(newValue ? "납부 요청이 승인되었습니다." : "납부 요청이 미승인 처리되었습니다."),
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
      } else {
        _revertSwitch(paymentId);
        _showErrorDialog(data["message"] ?? "처리에 실패했습니다.");
      }
    } catch (e) {
      _revertSwitch(paymentId);
      _showErrorDialog("상태 변경 중 오류 발생: $e");
    }
  }

  void _revertSwitch(String paymentId) {
    setState(() {
      _switchValues[paymentId] = !_switchValues[paymentId]!;
    });
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("오류"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인", style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "납부 내역 목록"),
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
                              return _buildPaymentList();
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildPaymentList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _isPaymentLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentData.isEmpty
              ? Center(
                  child: Align(
                    alignment: const Alignment(0.0, -0.15),
                    child: Text(
                      '납부 내역 목록이 없습니다',
                      style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF334D61).withOpacity(0.5),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : ListView(
                  children: _paymentData.keys
                      .map((paymentId) => _buildListItem(paymentId))
                      .toList(),
                ),
    );
  }

  Widget _buildListItem(String paymentId) {
    final name = _paymentData[paymentId]?['name'] ?? "이름 없음";
    final studentId = _paymentData[paymentId]?['studentId'] ?? "ID 없음";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SendPaymentDetailScreen(paymentId: paymentId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF334D61).withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                studentId,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            CupertinoSwitch(
              value: _switchValues[paymentId] ?? false,
              activeTrackColor: const Color(0xFF334D61),
              onChanged: (bool value) {
                _toggleApproval(
                  paymentId: paymentId,
                  newValue: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
