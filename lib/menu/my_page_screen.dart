import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/menu_button.dart';
import 'package:passtime/menu/affiliation_creation.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/screens/ticket_screen.dart';

class Affiliation {
  final String id;
  final String name;
  final bool admin;

  Affiliation({required this.id, required this.name, required this.admin});

  factory Affiliation.fromJson(Map<String, dynamic> json) {
    return Affiliation(
      id: json['_id'],
      name: json['name'],
      admin: json['admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'admin': admin,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Affiliation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final Dio _dio = Dio();
  Affiliation? _selectedAffiliation;
  List<Affiliation> _currentAffiliations = [];
  late List<Affiliation> _initialAffiliations;
  List<Affiliation> _availableAffiliations = [];

  bool _isSaveButtonEnabled = false;
  String _fixedStudentId = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);
        options.headers['Cookie'] = cookies.isNotEmpty
            ? cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ')
            : '';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final responseCookies = response.headers['set-cookie'];
        if (responseCookies != null && responseCookies.isNotEmpty) {
          final parsedCookies = responseCookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();
          CookieJarSingleton().cookieJar.saveFromResponse(uri, parsedCookies);
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));

    _fetchMyPageData();
  }

  Future<void> _fetchMyPageData() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/user/mypage';
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookieHeader,
          },
        ),
      );

      print('마이페이지 데이터 수신: ${response.data}');

      if (response.data['code'] == 'SUCCESS-0000') {
        final result = response.data['result'];

        final List<Affiliation> affiliations = (result['affiliations']
                    as List<dynamic>? ??
                [])
            .map((item) => Affiliation.fromJson(item as Map<String, dynamic>))
            .toList();

        final String studentId = result['studentId']?.toString() ?? '';
        final String name = result['name'] ?? '';

        final List<Affiliation> totalAffiliations = (result['totalAffiliation']
                    as List<dynamic>? ??
                [])
            .map((item) => Affiliation.fromJson(item as Map<String, dynamic>))
            .toList();

        setState(() {
          _currentAffiliations = affiliations;
          _initialAffiliations = List.from(_currentAffiliations);
          _fixedStudentId = studentId;
          _userName = name;

          _availableAffiliations = totalAffiliations
              .where((totalAff) => !_currentAffiliations.contains(totalAff))
              .toList();

          _updateSaveButtonState();
        });
      } else {
        print(
            'API 오류: code = ${response.data['code']}, message = ${response.data['message']}');
      }
    } catch (e, st) {
      print('서버 요청 실패: $e');
      print('Stacktrace: $st');
    }
  }

  bool _areListsEqual(List<Affiliation> list1, List<Affiliation> list2) {
    if (list1.length != list2.length) return false;
    final set1 = list1.map((e) => e.id).toSet();
    final set2 = list2.map((e) => e.id).toSet();
    return set1.difference(set2).isEmpty && set2.difference(set1).isEmpty;
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled =
          !_areListsEqual(_currentAffiliations, _initialAffiliations);
    });
  }

  Widget _buildAffiliationItem(Affiliation affiliation,
      {bool canRemove = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            affiliation.name,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          if (canRemove)
            InkWell(
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (BuildContext dialogContext) => CupertinoAlertDialog(
                    title: const Text('주의사항'),
                    content: const Text(
                        '소속을 제거하면 관련 권한이 삭제되며\n필요한 경우 다시 신청해야 합니다.\n정말 삭제하시겠습니까?'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('취소'),
                      ),
                      CupertinoDialogAction(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          setState(() {
                            _currentAffiliations.remove(affiliation);
                            if (!_availableAffiliations.contains(affiliation)) {
                              _availableAffiliations.add(affiliation);
                              _availableAffiliations
                                  .sort((a, b) => a.name.compareTo(b.name));
                            }
                            _updateSaveButtonState();
                          });
                        },
                        child: const Text('삭제',
                            style: TextStyle(color: Color(0xFFC10230))),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.remove, color: Color(0xFF334D61)),
            )
          else
            const Icon(Icons.remove, color: Color(0xFF868686)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로가기 동작을 가로챕니다.
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // 뒤로가기 동작을 감지하면 TicketScreen으로 이동합니다.
        // pushAndRemoveUntil을 사용하여 TicketScreen을 새 스택의 루트로 만듭니다.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TicketScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        appBar: const CustomAppBar(title: '마이페이지'),
        backgroundColor: const Color(0xFFF5F6F7),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        '안녕하세요 $_userName님 :)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334D61),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '학번',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              child: Text(
                                _fixedStudentId,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        '현재 소속',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334D61),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _currentAffiliations.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  '현재 등록된 소속이 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF868686),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0;
                                    i < _currentAffiliations.length;
                                    i++) ...[
                                  _buildAffiliationItem(_currentAffiliations[i],
                                      canRemove: true),
                                  if (i < _currentAffiliations.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '소속 추가',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334D61),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AffiliationCreationScreen(
                                    hostName: _userName,
                                    studentId: _fixedStudentId,
                                  ),
                                ),
                              );
                              _fetchMyPageData();
                            },
                            label: const Text(
                              '소속 생성',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.add_rounded,
                                color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7E929F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          dividerColor: Colors.transparent,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ExpansionTile(
                            key: ValueKey(_selectedAffiliation),
                            title: Text(
                              _selectedAffiliation?.name ?? '추가할 소속 선택',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedAffiliation == null
                                    ? const Color(0xFF868686)
                                    : const Color(0xFF282727),
                              ),
                            ),
                            trailing: const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFF868686)),
                            children: [
                              SizedBox(
                                height: _availableAffiliations.length > 5
                                    ? (5 * 48.0)
                                    : _availableAffiliations.length * 48.0,
                                child: ListView.builder(
                                  itemCount: _availableAffiliations.length,
                                  itemBuilder: (context, index) {
                                    final affiliation =
                                        _availableAffiliations[index];
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (!_currentAffiliations
                                              .contains(affiliation)) {
                                            _currentAffiliations
                                                .add(affiliation);
                                            _availableAffiliations
                                                .remove(affiliation);
                                            _selectedAffiliation = null;
                                          }
                                          _updateSaveButtonState();
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 12),
                                        child: Text(
                                          affiliation.name,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF282727)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16.0,
                0,
                16.0,
                MediaQuery.of(context).viewPadding.bottom > 0
                    ? 16.0
                    : 0.0, // 👈 조건부 여백
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSaveButtonEnabled
                      ? () async {
                          final apiUrl =
                              '${dotenv.env['API_BASE_URL']}/user/affiliationUpdate';
                          final uri =
                              Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

                          try {
                            final cookies = await CookieJarSingleton()
                                .cookieJar
                                .loadForRequest(uri);
                            final cookieHeader = cookies.isNotEmpty
                                ? cookies
                                    .map((cookie) =>
                                        '${cookie.name}=${cookie.value}')
                                    .join('; ')
                                : '';

                            final List<Map<String, dynamic>> payloadList = [];
                            for (final currentAff in _currentAffiliations) {
                              bool wasInitiallyPresent =
                                  _initialAffiliations.any((initialAff) =>
                                      initialAff.id == currentAff.id);

                              if (wasInitiallyPresent) {
                                final originalAff =
                                    _initialAffiliations.firstWhere(
                                        (aff) => aff.id == currentAff.id);
                                payloadList.add(originalAff.toJson());
                              } else {
                                payloadList.add({
                                  '_id': currentAff.id,
                                  'name': currentAff.name,
                                  'admin': false,
                                });
                              }
                            }

                            final response = await _dio.put(
                              apiUrl,
                              data: {
                                "affiliationList": payloadList,
                              },
                              options: Options(
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Cookie': cookieHeader,
                                },
                              ),
                            );

                            print('저장 API 응답 데이터: ${response.data}');

                            if (!context.mounted) return;

                            if (response.data['code'] != null &&
                                response.data['code'].startsWith('SUCCESS')) {
                              setState(() {
                                _initialAffiliations =
                                    List.from(_currentAffiliations);
                                _isSaveButtonEnabled = false;
                              });
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('저장 완료'),
                                  content: const Text('소속 정보가 성공적으로 저장되었습니다.'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text("확인",
                                          style: TextStyle(
                                              color: Color(0xFFC10230))),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('저장 실패'),
                                  content: Text(response.data['message'] ??
                                      '알 수 없는 오류가 발생했습니다.'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text("확인",
                                          style: TextStyle(
                                              color: Color(0xFFC10230))),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('오류 발생'),
                                content:
                                    const Text('요청 중 오류가 발생했습니다. 다시 시도해주세요.'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text("확인",
                                        style: TextStyle(
                                            color: Color(0xFFC10230))),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC10230),
                    disabledBackgroundColor:
                        const Color(0xFFC10230).withOpacity(0.3),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withOpacity(0.7),
                  ),
                  child: const Text('저장',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: const Padding(
          padding: EdgeInsets.only(bottom: 60.0),
          child: MenuButton(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
