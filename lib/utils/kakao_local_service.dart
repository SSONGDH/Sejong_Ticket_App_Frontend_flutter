import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class KakaoLocalService {
  static Map<String, String> get _headers => {
        'Authorization': 'KakaoAK ${dotenv.env['KAKAO_REST_API_KEY']}',
      };

  static Future<Map<String, dynamic>?> geocodeAddress(String query) async {
    if (query.trim().isEmpty) return null;

    final addressResults = await _searchAddress(query);
    if (addressResults.isNotEmpty) return addressResults.first;

    final keywordResults = await _searchKeyword(query);
    if (keywordResults.isNotEmpty) return keywordResults.first;

    return null;
  }

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await Future.wait([
      _searchKeyword(query),
      _searchAddress(query),
    ]);

    final merged = <String, Map<String, dynamic>>{};
    for (final list in results) {
      for (final place in list) {
        final key = '${place['x']}_${place['y']}';
        merged.putIfAbsent(key, () => place);
      }
    }
    return merged.values.toList();
  }

  static Future<List<Map<String, dynamic>>> _searchKeyword(String query) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}',
    );
    final response = await http.get(url, headers: _headers);
    if (response.statusCode != 200) return [];

    final documents =
        List<Map<String, dynamic>>.from(json.decode(response.body)['documents']);
    return documents.map(_normalizePlace).toList();
  }

  static Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeQueryComponent(query)}',
    );
    final response = await http.get(url, headers: _headers);
    if (response.statusCode != 200) return [];

    final documents =
        List<Map<String, dynamic>>.from(json.decode(response.body)['documents']);
    return documents.map(_normalizePlace).toList();
  }

  static Map<String, dynamic> _normalizePlace(Map<String, dynamic> place) {
    final placeName = (place['place_name'] ?? place['address_name'] ?? '')
        .toString()
        .trim();
    final addressName = (place['address_name'] ?? placeName).toString().trim();

    return {
      'place_name': placeName.isNotEmpty ? placeName : addressName,
      'address_name': addressName,
      'x': place['x'].toString(),
      'y': place['y'].toString(),
    };
  }

  static Future<String> coordToAddress({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$longitude&y=$latitude',
    );
    final response = await http.get(url, headers: _headers);
    if (response.statusCode != 200) {
      return '선택한 위치';
    }

    final documents = json.decode(response.body)['documents'] as List<dynamic>;
    if (documents.isEmpty) return '선택한 위치';

    final doc = documents.first as Map<String, dynamic>;
    final road = doc['road_address'];
    final jibun = doc['address'];

    if (road is Map<String, dynamic> &&
        (road['address_name']?.toString().isNotEmpty ?? false)) {
      return road['address_name'].toString();
    }
    if (jibun is Map<String, dynamic> &&
        (jibun['address_name']?.toString().isNotEmpty ?? false)) {
      return jibun['address_name'].toString();
    }
    return '선택한 위치';
  }

  static Map<String, dynamic> buildCustomPlace({
    required String placeName,
    required String addressName,
    required double latitude,
    required double longitude,
  }) {
    return {
      'place_name': placeName,
      'address_name': addressName,
      'x': longitude.toString(),
      'y': latitude.toString(),
    };
  }
}
