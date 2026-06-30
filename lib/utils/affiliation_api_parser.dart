import 'package:passtime/models/authorized_affiliation.dart';

/// 권한·주최자 모드 관련 API 응답 파싱 유틸
class AffiliationApiParser {
  AffiliationApiParser._();

  /// GET /user/affiliation/authorized 응답 파싱
  /// - 신규: { root, affiliations: [...] }
  /// - 구형: [...] (배열 직접 반환)
  static List<AuthorizedAffiliation> parseAuthorizedAffiliations(
    dynamic result, {
    bool asRootBadge = false,
  }) {
    if (result == null) return [];

    if (result is List) {
      return result
          .map(
            (item) => AuthorizedAffiliation.fromJson(
              Map<String, dynamic>.from(item as Map),
              isRootBadge: asRootBadge,
            ),
          )
          .toList();
    }

    if (result is Map) {
      final map = Map<String, dynamic>.from(result);
      final affiliations = map['affiliations'];

      if (affiliations is List) {
        return affiliations
            .map(
              (item) => AuthorizedAffiliation.fromJson(
                Map<String, dynamic>.from(item as Map),
                isRootBadge: asRootBadge,
              ),
            )
            .toList();
      }
    }

    return [];
  }

  /// 주최자 모드 진입 가능 여부 (authorized API result 기준)
  static bool hasAuthorizedAffiliations(dynamic result) {
    if (result == null) return false;

    if (result is List) return result.isNotEmpty;

    if (result is Map) {
      if (result['root'] == true) return true;
      final affiliations = result['affiliations'];
      return affiliations is List && affiliations.isNotEmpty;
    }

    return false;
  }

  /// GET /user/adminAffilliation/list 응답 파싱
  static List<Map<String, dynamic>> parseHostAffiliations(dynamic data) {
    if (data == null) return [];

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (map['success'] == true && map['affiliations'] is List) {
        return _normalizeHostAffiliations(map['affiliations'] as List);
      }

      if (map['isSuccess'] == true) {
        final result = map['result'];
        if (result is List) {
          return _normalizeHostAffiliations(result);
        }
        if (result is Map && result['affiliations'] is List) {
          return _normalizeHostAffiliations(result['affiliations'] as List);
        }
      }
    }

    return [];
  }

  static List<Map<String, dynamic>> _normalizeHostAffiliations(List list) {
    return list.map((item) {
      final aff = Map<String, dynamic>.from(item as Map);
      final id = affiliationId(aff);
      if (id != null) {
        aff['_id'] ??= id;
        aff['affiliationId'] ??= id;
      }
      return aff;
    }).toList();
  }

  static String? affiliationId(Map<String, dynamic> affiliation) {
    final id = affiliation['affiliationId'] ?? affiliation['_id'];
    if (id == null) return null;
    final text = id.toString();
    return text.isEmpty ? null : text;
  }

  static String affiliationName(Map<String, dynamic> affiliation) {
    return affiliation['name']?.toString() ?? '';
  }

  /// 신청 유형 라벨 (구형 '주최자 권한' → '임원 권한' 하위 호환)
  static String resolveRequestTypeLabel(Map<String, dynamic> request) {
    final label = request['requestTypeLabel']?.toString() ?? '';
    if (label == '주최자 권한') return '임원 권한';
    if (label.isNotEmpty) return label;

    final requestType = request['requestType']?.toString() ??
        (request['createAffiliation'] == true ? 'create' : 'admin');

    switch (requestType) {
      case 'create':
        return '소속 생성';
      case 'admin':
        return '임원 권한';
      default:
        return '신청';
    }
  }
}
