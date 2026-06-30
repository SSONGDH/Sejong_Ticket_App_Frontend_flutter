import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:passtime/models/affiliation_member.dart';
import 'package:passtime/widgets/custom_app_bar.dart';
import 'package:passtime/widgets/menu_button.dart';

enum _MemberSortOption {
  roleFirst('권한순'),
  nameAsc('이름순'),
  studentIdAsc('학번순');

  const _MemberSortOption(this.label);
  final String label;
}

class AffiliationMembersScreen extends StatefulWidget {
  final String affiliationId;
  final String affiliationName;
  final bool canManagePermissions;
  final String viewerStudentId;
  final bool viewerIsRoot;

  const AffiliationMembersScreen({
    super.key,
    required this.affiliationId,
    required this.affiliationName,
    required this.canManagePermissions,
    required this.viewerStudentId,
    this.viewerIsRoot = false,
  });

  @override
  State<AffiliationMembersScreen> createState() =>
      _AffiliationMembersScreenState();
}

class _AffiliationMembersScreenState extends State<AffiliationMembersScreen> {
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();

  List<AffiliationMember> _members = [];
  int _privilegedCount = 0;
  int _maxPrivilegedCount = 3;
  int _membersCount = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _viewerIsRoot = false;
  _MemberSortOption _sortOption = _MemberSortOption.roleFirst;
  String? _expandedStudentId;

  @override
  void initState() {
    super.initState();
    _viewerIsRoot = widget.viewerIsRoot;
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
      onError: (error, handler) => handler.next(error),
    ));

    _searchController.addListener(() => setState(() {}));
    _fetchMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);

    try {
      final apiUrl =
          '${dotenv.env['API_BASE_URL']}/affiliation/members/${widget.affiliationId}';
      final response = await _dio.get(apiUrl);

      if (response.data['isSuccess'] == true && response.data['result'] != null) {
        final result = response.data['result'] as Map<String, dynamic>;
        final members = (result['members'] as List<dynamic>? ?? [])
            .map((item) =>
                AffiliationMember.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _members = members;
            _privilegedCount = result['privilegedCount'] as int? ?? 0;
            _maxPrivilegedCount = result['maxPrivilegedCount'] as int? ?? 3;
            _membersCount = result['membersCount'] as int? ?? members.length;
            if (result['viewerIsRoot'] == true) {
              _viewerIsRoot = true;
            }
          });
        }
      }
    } catch (_) {
      if (mounted) _showErrorDialog('멤버 목록을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AffiliationMember> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    var members = List<AffiliationMember>.from(_members);

    if (query.isNotEmpty) {
      members = members
          .where((member) =>
              member.name.toLowerCase().contains(query) ||
              member.studentId.toLowerCase().contains(query) ||
              member.major.toLowerCase().contains(query))
          .toList();
    }

    members.sort((a, b) {
      switch (_sortOption) {
        case _MemberSortOption.nameAsc:
          return a.name.compareTo(b.name);
        case _MemberSortOption.studentIdAsc:
          return a.studentId.compareTo(b.studentId);
        case _MemberSortOption.roleFirst:
          final roleOrder = {'leader': 0, 'executive': 2, 'member': 3};
          final orderA = (roleOrder[a.role] ?? 4) - (a.isRoot ? 1 : 0);
          final orderB = (roleOrder[b.role] ?? 4) - (b.isRoot ? 1 : 0);
          if (orderA != orderB) return orderA.compareTo(orderB);
          return a.name.compareTo(b.name);
      }
    });

    return members;
  }

  Future<void> _postPermissionAction(
    String path,
    String targetStudentId, {
    required String successMessage,
  }) async {
    setState(() => _isProcessing = true);

    try {
      final response = await _dio.post(
        '${dotenv.env['API_BASE_URL']}/affiliation/permission/$path',
        data: {
          'affiliationId': widget.affiliationId,
          'targetStudentId': targetStudentId,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (!mounted) return;

      if (response.data['isSuccess'] == true) {
        if (mounted) setState(() => _expandedStudentId = null);
        await _fetchMembers();
        if (mounted) {
          _showSuccessDialog(successMessage);
        }
      } else {
        _showErrorDialog(
          response.data['message']?.toString() ?? '요청에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        e.response?.data?['message']?.toString() ?? '요청 중 오류가 발생했습니다.',
      );
    } catch (_) {
      if (mounted) _showErrorDialog('요청 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('완료'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );

    if (confirmed == true) onConfirm();
  }

  bool _canShowActionsFor(AffiliationMember member) {
    if (!widget.canManagePermissions) return false;
    if (member.role == 'leader') return false;

    final isSelf = member.studentId == widget.viewerStudentId;
    if (isSelf) return _viewerIsRoot;

    return true;
  }

  void _toggleExpanded(AffiliationMember member) {
    if (!_canShowActionsFor(member)) return;

    setState(() {
      _expandedStudentId =
          _expandedStudentId == member.studentId ? null : member.studentId;
    });
  }

  Widget _buildSlideAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        child: SizedBox(
          width: 76,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMemberActionButtons(AffiliationMember member) {
    final actions = <Widget>[];
    final isSelf = member.studentId == widget.viewerStudentId;

    if (isSelf && _viewerIsRoot) {
      actions.add(
        _buildSlideAction(
          label: '소속장\n되기',
          color: const Color(0xFFC10230),
          onTap: () => _confirmAction(
            title: '소속장 지정',
            message: '본인을 소속장으로 지정할까요?\n기존 소속장은 일반 멤버가 됩니다.',
            onConfirm: () => _postPermissionAction(
              'delegate',
              member.studentId,
              successMessage: '소속장으로 지정되었습니다.',
            ),
          ),
        ),
      );
      return actions;
    }

    if (member.role == 'member') {
      if (_privilegedCount < _maxPrivilegedCount) {
        actions.add(
          _buildSlideAction(
            label: '권한\n부여',
            color: const Color(0xFF7E929F),
            onTap: () => _confirmAction(
              title: '임원 권한 부여',
              message: '${member.name}님에게 임원 권한을 부여할까요?',
              onConfirm: () => _postPermissionAction(
                'grant',
                member.studentId,
                successMessage: '임원 권한이 부여되었습니다.',
              ),
            ),
          ),
        );
      }
      actions.add(
        _buildSlideAction(
          label: '소속장\n위임',
          color: const Color(0xFF334D61),
          onTap: () => _confirmAction(
            title: '소속장 위임',
            message: '${member.name}님에게 소속장을 위임할까요?\n위임 후 본인은 일반 멤버가 됩니다.',
            onConfirm: () => _postPermissionAction(
              'delegate',
              member.studentId,
              successMessage: '소속장 위임이 완료되었습니다.',
            ),
          ),
        ),
      );
    } else if (member.role == 'executive') {
      actions.add(
        _buildSlideAction(
          label: '권한\n삭제',
          color: const Color(0xFFC10230),
          onTap: () => _confirmAction(
            title: '임원 권한 삭제',
            message: '${member.name}님의 임원 권한을 삭제할까요?',
            onConfirm: () => _postPermissionAction(
              'revoke',
              member.studentId,
              successMessage: '임원 권한이 삭제되었습니다.',
            ),
          ),
        ),
      );
    }

    return actions;
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
              ..._MemberSortOption.values.map((option) {
                final isSelected = _sortOption == option;
                return ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFC10230)
                          : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFFC10230))
                      : null,
                  onTap: () {
                    setState(() => _sortOption = option);
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

  Widget _buildRootBadge() {
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

  Widget _buildRoleBadge(String roleLabel, String role) {
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
        roleLabel,
        style: TextStyle(
          color: isExecutive ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMemberBadges(AffiliationMember member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRoleBadge(member.roleLabel, member.role),
        if (_viewerIsRoot && member.isRoot) ...[
          const SizedBox(width: 4),
          _buildRootBadge(),
        ],
      ],
    );
  }

  Widget _buildMemberItem(AffiliationMember member) {
    final canShowActions = _canShowActionsFor(member);
    final isExpanded =
        canShowActions && _expandedStudentId == member.studentId;
    final actionButtons = isExpanded ? _buildMemberActionButtons(member) : <Widget>[];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleExpanded(member),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: isExpanded
                      ? Colors.white
                      : const Color(0xFF334D61).withOpacity(0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMemberBadges(member),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${member.studentId} · ${member.major.isNotEmpty ? member.major : '-'}',
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
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: isExpanded ? actionButtons : const [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _filteredMembers;
    final hasData = _members.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: '소속 멤버'),
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
                  widget.affiliationName,
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
                      TextSpan(
                        text: '총 $_membersCount명',
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
                        text: '권한 $_privilegedCount/$_maxPrivilegedCount명',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canManagePermissions) ...[
                  const SizedBox(height: 6),
                  Text(
                    _viewerIsRoot
                        ? '멤버를 탭하면 권한 부여·위임·삭제·소속장 지정 메뉴가 열려요'
                        : '멤버를 탭하면 권한 부여·위임·삭제 메뉴가 열려요',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334D61).withOpacity(0.5),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasData)
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
                          '멤버가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF334D61).withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : filteredMembers.isEmpty
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
                            onRefresh: _fetchMembers,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) =>
                                  _buildMemberItem(filteredMembers[index]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: const MenuButton(),
    );
  }
}
