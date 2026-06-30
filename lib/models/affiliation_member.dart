class AffiliationMember {
  final String name;
  final String studentId;
  final String major;
  final String role;
  final String roleLabel;
  final bool admin;
  final bool isRoot;

  const AffiliationMember({
    required this.name,
    required this.studentId,
    required this.major,
    required this.role,
    required this.roleLabel,
    required this.admin,
    this.isRoot = false,
  });

  factory AffiliationMember.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString() ??
        (json['admin'] == true ? 'leader' : 'member');

    return AffiliationMember(
      name: json['name']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      major: json['major']?.toString() ?? '',
      role: role,
      roleLabel: json['roleLabel']?.toString() ??
          AuthorizedAffiliationRole.defaultLabel(role),
      admin: json['admin'] == true,
      isRoot: json['isRoot'] == true,
    );
  }
}

class AuthorizedAffiliationRole {
  static String defaultLabel(String role) {
    switch (role) {
      case 'leader':
        return '소속장';
      case 'executive':
        return '임원';
      case 'member':
        return '일반';
      default:
        return '';
    }
  }
}
