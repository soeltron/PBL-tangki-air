import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? token;

  static Future<void> loadToken() async {
    token = await _storage.read(key: 'token');
  }

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiUrl}/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) return false;
    token = jsonDecode(res.body)['token'];
    await _storage.write(key: 'token', value: token);
    return true;
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('${AppConfig.apiUrl}/logout'),
          headers: _headers);
    } catch (_) {}
    token = null;
    await _storage.delete(key: 'token');
  }

  static Future<Map<String, dynamic>> latest() async {
    final res = await http.get(Uri.parse('${AppConfig.apiUrl}/latest'),
        headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> history(
      {String? device, String? from, String? to, int page = 1}) async {
    final q = {
      'device': device,
      'from': from,
      'to': to,
      'page': '$page',
    };
    final uri = Uri.parse('${AppConfig.apiUrl}/history')
        .replace(queryParameters: q);
    final res = await http.get(uri, headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final res = await http.get(Uri.parse('${AppConfig.apiUrl}/settings'),
        headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateSettings(
      Map<String, num> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiUrl}/settings'),
        headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }
}