import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class Api {
  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  static Future<void> saveAuth(String token, Map user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', token);
    await preferences.setString('user', jsonEncode(user));
  }

  static Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  static Future<dynamic> request(
    String method,
    String path, {
    Map? body,
    bool auth = true,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final currentToken = await token();
      if (currentToken != null && currentToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $currentToken';
      }
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    final data =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data is Map ? (data['message'] ?? 'Request failed') : 'Request failed',
      );
    }
    return data;
  }

  static Future<dynamic> returnBook(int bookId) async {
    return await request(
      'POST',
      '/books/$bookId/return',
    );
  }
}
