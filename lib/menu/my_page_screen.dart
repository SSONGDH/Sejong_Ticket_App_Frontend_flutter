import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/menu_button.dart';
import 'package:passtime/menu/affiliation_creation.dart';
import 'package:passtime/menu/affiliation_members_screen.dart';
import 'package:passtime/menu/my_request_history_screen.dart';
import 'package:passtime/models/authorized_affiliation.dart';
import 'package:passtime/utils/affiliation_api_parser.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/screens/ticket_screen.dart';

class Affiliation {
  final String id;
  final String name;
  final bool admin;
  final String? role;

  Affiliation({
    required this.id,
    required this.name,
    required this.admin,
    this.role,
  });

  factory Affiliation.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString();
    final admin = json['admin'] as bool? ??
        (role == 'leader' || role == 'executive');

    return Affiliation(
      id: (json['_id'] ?? json['affiliationId'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      admin: admin,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      '_id': id,
      'name': name,
      'admin': admin,
    };
    if (role != null && role!.isNotEmpty) {
      json['role'] = role;
    }
    return json;
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
  static const double _dropdownItemHeight = 48.0;
  static const int _maxDropdownVisibleItems = 4;

  final Dio _dio = Dio();
  Affiliation? _selectedAffiliation;
  List<Affiliation> _currentAffiliations = [];
  late List<Affiliation> _initialAffiliations;
  List<Affiliation> _availableAffiliations = [];
  List<AuthorizedAffiliation> _authorizedAffiliations = [];

  bool _isSaving = false;
  bool _isRoot = false;
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
        final bool isRoot = result['root'] == true;

        final List<Affiliation> totalAffiliations = (result['totalAffiliation']
                    as List<dynamic>? ??
                [])
            .map((item) => Affiliation.fromJson(item as Map<String, dynamic>))
            .toList();

        final List<AuthorizedAffiliation> authorizedAffiliations = isRoot
            ? (totalAffiliations
                .map((aff) => AuthorizedAffiliation(
                      id: aff.id,
                      name: aff.name,
                      role: 'leader',
                      roleLabel: 'ROOT',
                      isRootBadge: true,
                      canManagePermissions: true,
                    ))
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name)))
            : await _fetchAuthorizedAffiliations();

        setState(() {
          _currentAffiliations = affiliations;
          _initialAffiliations = List.from(_currentAffiliations);
          _fixedStudentId = studentId;
          _userName = name;
          _isRoot = isRoot;
          _authorizedAffiliations = authorizedAffiliations;

          _availableAffiliations = totalAffiliations
              .where((totalAff) => !_currentAffiliations.contains(totalAff))
              .toList();
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

  Future<List<AuthorizedAffiliation>> _fetchAuthorizedAffiliations() async {
    final apiUrl =
        '${dotenv.env['API_BASE_URL']}/user/affiliation/authorized';
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

      if (response.data['isSuccess'] == true) {
        return AffiliationApiParser.parseAuthorizedAffiliations(
          response.data['result'],
        );
      }
    } catch (e) {
      print('권한 소속 목록 조회 실패: $e');
    }

    return [];
  }

  Future<bool> _saveAffiliations({bool showSuccessDialog = false}) async {
    if (_isSaving) return false;

    setState(() => _isSaving = true);

    final apiUrl = '${dotenv.env['API_BASE_URL']}/user/affiliationUpdate';
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    try {
      final cookies =
          await CookieJarSingleton().cookieJar.loadForRequest(uri);
      final cookieHeader = cookies.isNotEmpty
          ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
          : '';

      final List<Map<String, dynamic>> payloadList = [];
      for (final currentAff in _currentAffiliations) {
        final wasInitiallyPresent = _initialAffiliations
            .any((initialAff) => initialAff.id == currentAff.id);

        if (wasInitiallyPresent) {
          final originalAff = _initialAffiliations
              .firstWhere((aff) => aff.id == currentAff.id);
          payloadList.add(originalAff.toJson());
        } else {
          payloadList.add({
            '_id': currentAff.id,
            'name': currentAff.name,
            'admin': false,
            'role': 'member',
          });
        }
      }

      final response = await _dio.put(
        apiUrl,
        data: {'affiliationList': payloadList},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookieHeader,
          },
        ),
      );

      if (!mounted) return false;

      if (response.data['code'] != null &&
          response.data['code'].toString().startsWith('SUCCESS')) {
        setState(() {
          _initialAffiliations = List.from(_currentAffiliations);
        });

        if (showSuccessDialog) {
          await showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('저장 완료'),
              content: const Text('소속 정보가 성공적으로 저장되었습니다.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('확인',
                      style: TextStyle(color: Color(0xFFC10230))),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
        return true;
      }

      _showSaveErrorDialog(
        response.data['message']?.toString() ?? '알 수 없는 오류가 발생했습니다.',
      );
      return false;
    } on DioException catch (e) {
      if (mounted) {
        _showSaveErrorDialog(
          e.response?.data?['message']?.toString() ??
              '요청 중 오류가 발생했습니다. 다시 시도해주세요.',
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        _showSaveErrorDialog('요청 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSaveErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('저장 실패'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child:
                const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _addAffiliation(Affiliation affiliation) async {
    if (_isSaving || _currentAffiliations.contains(affiliation)) return;

    setState(() {
      _currentAffiliations.add(affiliation);
      _availableAffiliations.remove(affiliation);
      _selectedAffiliation = null;
    });

    final success = await _saveAffiliations();
    if (!success && mounted) {
      setState(() {
        _currentAffiliations.remove(affiliation);
        if (!_availableAffiliations.contains(affiliation)) {
          _availableAffiliations.add(affiliation);
          _availableAffiliations.sort((a, b) => a.name.compareTo(b.name));
        }
      });
    }
  }

  Future<void> _removeAffiliation(Affiliation affiliation) async {
    if (_isSaving) return;

    setState(() {
      _currentAffiliations.remove(affiliation);
      if (!_availableAffiliations.contains(affiliation)) {
        _availableAffiliations.add(affiliation);
        _availableAffiliations.sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final success = await _saveAffiliations();
    if (success && mounted) {
      await _fetchMyPageData();
      return;
    }

    if (!success && mounted) {
      setState(() {
        if (!_currentAffiliations.contains(affiliation)) {
          _currentAffiliations.add(affiliation);
        }
        _availableAffiliations.remove(affiliation);
      });
    }
  }

  String _normalizedRole(Affiliation affiliation) {
    final role = affiliation.role;
    if (role == 'leader' || role == 'executive' || role == 'member') {
      return role!;
    }
    return affiliation.admin ? 'leader' : 'member';
  }

  bool _isAffiliationLeader(Affiliation affiliation) =>
      _normalizedRole(affiliation) == 'leader';

  bool _isAffiliationExecutive(Affiliation affiliation) =>
      _normalizedRole(affiliation) == 'executive';

  void _showRemoveAffiliationDialog(Affiliation affiliation) {
    if (_isAffiliationLeader(affiliation)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('안내'),
          content: const Text(
            '소속을 나가려면\n소속장 위임을 먼저 진행해 주세요.',
            textAlign: TextAlign.center,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
            ),
          ],
        ),
      );
      return;
    }

    final isExecutive = _isAffiliationExecutive(affiliation);
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('주의사항'),
        content: Text(
          isExecutive
              ? '임원 권한이 해제되고 소속에서 나갑니다.\n정말 나가시겠습니까?'
              : '소속을 제거하면 관련 권한이 삭제되며\n필요한 경우 다시 신청해야 합니다.\n정말 삭제하시겠습니까?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(dialogContext);
              _removeAffiliation(affiliation);
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  Color _roleBadgeColor(String role) {
    switch (role) {
      case 'leader':
        return const Color(0xFFC10230);
      case 'executive':
        return const Color(0xFF7E929F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildAuthorizedRoleBadge(AuthorizedAffiliation affiliation) {
    if (affiliation.isRootBadge) {
      const color = Color(0xFFC10230);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'ROOT',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final role = affiliation.role;
    if (role == 'member') return const SizedBox.shrink();

    final color = _roleBadgeColor(role);
    final isExecutive = role == 'executive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isExecutive ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        affiliation.roleLabel,
        style: TextStyle(
          color: isExecutive ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _openAffiliationMembers(AuthorizedAffiliation affiliation) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AffiliationMembersScreen(
          affiliationId: affiliation.id,
          affiliationName: affiliation.name,
          canManagePermissions:
              affiliation.canManagePermissions || _isRoot,
          viewerStudentId: _fixedStudentId,
          viewerIsRoot: _isRoot,
        ),
      ),
    );

    if (refreshed == true && mounted) {
      await _fetchMyPageData();
    }
  }

  Widget _buildAuthorizedAffiliationItem(AuthorizedAffiliation affiliation) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => _openAffiliationMembers(affiliation),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  affiliation.name,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              _buildAuthorizedRoleBadge(affiliation),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAffiliationItem(Affiliation affiliation) {
    final canRemove = !_isAffiliationLeader(affiliation);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              affiliation.name,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          InkWell(
            onTap: () => _showRemoveAffiliationDialog(affiliation),
            child: Icon(
              Icons.remove,
              color: canRemove
                  ? const Color(0xFF334D61)
                  : const Color(0xFF868686),
            ),
          ),
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
        resizeToAvoidBottomInset: false,
        appBar: const CustomAppBar(title: '마이페이지'),
        backgroundColor: const Color(0xFFF5F6F7),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '안녕하세요 $_userName님 :)',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334D61),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MyRequestHistoryScreen(),
                                ),
                              );
                            },
                            label: const Text(
                              '신청내역',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: const Icon(
                              Icons.assignment_outlined,
                              color: Colors.white,
                            ),
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
                        '내가 현재 속한 소속',
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
                                  _buildAffiliationItem(_currentAffiliations[i]),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
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
                                height: _availableAffiliations.isEmpty
                                    ? _dropdownItemHeight
                                    : (_availableAffiliations.length >
                                                _maxDropdownVisibleItems
                                            ? _maxDropdownVisibleItems
                                            : _availableAffiliations.length) *
                                        _dropdownItemHeight,
                                child: _availableAffiliations.isEmpty
                                    ? const Center(
                                        child: Text(
                                          '추가할 소속이 없습니다',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF868686),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        physics:
                                            const ClampingScrollPhysics(),
                                        itemCount:
                                            _availableAffiliations.length,
                                        itemBuilder: (context, index) {
                                          final affiliation =
                                              _availableAffiliations[index];
                                          return InkWell(
                                            onTap: _isSaving
                                                ? null
                                                : () => _addAffiliation(
                                                      affiliation,
                                                    ),
                                            child: SizedBox(
                                              height: _dropdownItemHeight,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 15),
                                                  child: Text(
                                                    affiliation.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFF282727),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
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
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '권한이 있는 소속',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334D61),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '소속장에게 권한을 부여받거나 소속을 생성하세요',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334D61)
                                      .withOpacity(0.45),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _authorizedAffiliations.isEmpty
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
                                  '권한이 있는 소속이 없습니다',
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
                                    i < _authorizedAffiliations.length;
                                    i++) ...[
                                  _buildAuthorizedAffiliationItem(
                                      _authorizedAffiliations[i]),
                                  if (i < _authorizedAffiliations.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                      const SizedBox(height: 100),
                    ],
                  ),
        ),
        floatingActionButton: const MenuButton(),
      ),
    );
  }
}
