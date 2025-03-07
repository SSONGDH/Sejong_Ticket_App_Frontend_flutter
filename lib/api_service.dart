import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  static Future<http.Response> login(String userId, String password) async {
    final String url = '$baseUrl/login';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userid': userId, 'password': password}),
    );

    return response;
  }
}
