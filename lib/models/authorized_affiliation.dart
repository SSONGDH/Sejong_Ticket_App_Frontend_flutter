class AuthorizedAffiliation {
  final String id;
  final String name;
  final String role;
  final String roleLabel;
  final bool isRootBadge;
  final bool canManagePermissions;

  const AuthorizedAffiliation({
    required this.id,
    required this.name,
    required this.role,
    required this.roleLabel,
    this.isRootBadge = false,
    required this.canManagePermissions,
  });

  factory AuthorizedAffiliation.fromJson(
    Map<String, dynamic> json, {
    bool isRootBadge = false,
  }) {
    final role = json['role']?.toString() ??
        (json['admin'] == true ? 'leader' : 'member');
    final roleLabel = isRootBadge
        ? 'ROOT'
        : (json['roleLabel']?.toString().isNotEmpty == true
            ? json['roleLabel'].toString()
            : _defaultRoleLabel(role));

    return AuthorizedAffiliation(
      id: (json['affiliationId'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: isRootBadge ? 'leader' : role,
      roleLabel: roleLabel,
      isRootBadge: isRootBadge,
      canManagePermissions: isRootBadge || role == 'leader',
    );
  }

  static String _defaultRoleLabel(String role) {
    switch (role) {
      case 'leader':
        return '소속장';
      case 'executive':
        return '임원';
      default:
        return '';
    }
  }
}
