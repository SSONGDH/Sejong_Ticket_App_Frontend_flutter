import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/widgets/menu_button.dart';
import 'package:PASSTIME/menu/affiliation_creation.dart';
import '../cookiejar_singleton.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final Dio _dio = Dio();
  String? _selectedAffiliation;
  List<String> _currentAffiliations = [];
  late List<String> _initialAffiliations;

  List<String> _availableAffiliations = [];
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

      print('API 호출 완료 - Status Code: ${response.statusCode}');
      print('Response Body: ${response.data}');

      if (response.data['code'] == 'SUCCESS-0000') {
        final result = response.data['result'];

        // ✅ 현재 소속: affiliations 배열에서 name만 추출
        final List<String> affiliations =
            (result['affiliations'] as List<dynamic>? ?? [])
                .map((item) => item['name'] as String)
                .toList();

        final String studentId = result['studentId']?.toString() ?? '';
        final String name = result['name'] ?? '';

        // ✅ 전체 소속: totalAffiliation 배열에서 name만 추출
        final List<String> totalAffiliations =
            (result['totalAffiliation'] as List<dynamic>? ?? [])
                .map((item) => item['name'] as String)
                .toList();

        print('받아온 소속: $affiliations');
        print('받아온 학번: $studentId');
        print('받아온 이름: $name');
        print('전체 소속 목록: $totalAffiliations');

        setState(() {
          _currentAffiliations = affiliations;
          _initialAffiliations = List.from(_currentAffiliations);
          _fixedStudentId = studentId;
          _userName = name;

          // 현재 소속에 없는 것만 추가 가능한 소속 목록에 넣기
          _availableAffiliations = totalAffiliations
              .where((aff) => !_currentAffiliations.contains(aff))
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

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled =
          !_areListsEqual(_currentAffiliations, _initialAffiliations);
    });
  }

  Widget _buildAffiliationItem(String affiliationName,
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
            affiliationName,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          if (canRemove)
            InkWell(
              onTap: () {
                setState(() {
                  _currentAffiliations.remove(affiliationName);
                  if (!_availableAffiliations.contains(affiliationName)) {
                    _availableAffiliations.add(affiliationName);
                    _availableAffiliations.sort();
                  }
                  _updateSaveButtonState();
                });
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
    return Scaffold(
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
                            style: TextStyle(fontSize: 16, color: Colors.black),
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
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentAffiliations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildAffiliationItem(
                            _currentAffiliations[index],
                            canRemove: true);
                      },
                    ),
                    const SizedBox(height: 10),
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
                          onPressed: () {
                            // ⭐ 이름과 학번만 전달하도록 수정 ⭐
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AffiliationCreationScreen(
                                  hostName: _userName,
                                  studentId: _fixedStudentId,
                                ),
                              ),
                            );
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
                            _selectedAffiliation ?? '추가할 소속 선택',
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
                                        _selectedAffiliation = affiliation;
                                        if (!_currentAffiliations
                                            .contains(affiliation)) {
                                          _currentAffiliations.add(affiliation);
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
                                        affiliation,
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
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isSaveButtonEnabled
                    ? () async {
                        print(
                            '저장 버튼 클릭: $_fixedStudentId, $_currentAffiliations');

                        final apiUrl =
                            '${dotenv.env['API_BASE_URL']}/user/affiliationUpdate';
                        final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

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

                          final response = await _dio.put(
                            apiUrl,
                            data: {
                              "affiliationList": _currentAffiliations
                                  .map((name) => {"name": name})
                                  .toList(),
                            },
                            options: Options(
                              headers: {
                                'Content-Type': 'application/json',
                                'Cookie': cookieHeader,
                              },
                            ),
                          );

                          print(
                              '저장 API 호출 완료 - Status Code: ${response.statusCode}');
                          print('Response Body: ${response.data}');

                          setState(() {
                            _initialAffiliations =
                                List.from(_currentAffiliations);
                            _isSaveButtonEnabled = false;
                          });
                        } catch (e) {
                          print('저장 API 호출 실패: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
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
    );
  }
}
