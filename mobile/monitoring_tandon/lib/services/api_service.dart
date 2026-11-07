import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _timeout = Duration(seconds: 10);
  static String? token;
  static String? role;
  static String? username;
  static int? userId;

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<void> loadToken() async {
    token = await _storage.read(key: 'token');
    role = await _storage.read(key: 'role');
    username = await _storage.read(key: 'username');
    userId = int.tryParse(await _storage.read(key: 'user_id') ?? '');
  }

  static Future<Map<String, dynamic>> login(
    String login,
    String password,
  ) async {
    final response = await _request(
      () => http.post(
        Uri.parse('${AppConfig.apiUrl}/login'),
        headers: _headers,
        body: jsonEncode({'login': login, 'password': password}),
      ),
    );
    final tokenValue = response['token'];
    final userValue = response['user'];
    if (tokenValue is! String || userValue is! Map<String, dynamic>) {
      throw const FormatException('Respons login server tidak valid.');
    }

    token = tokenValue;
    role = userValue['role'] is String ? userValue['role'] as String : 'user';
    userId = userValue['id'] is num ? (userValue['id'] as num).toInt() : null;
    username = userValue['name'] is String
        ? userValue['name'] as String
        : login;
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'username', value: username);
    if (userId != null) {
      await _storage.write(key: 'user_id', value: '$userId');
    }
    return userValue;
  }

  static Future<void> logout() async {
    try {
      await _request(
        () => http.post(
          Uri.parse('${AppConfig.apiUrl}/logout'),
          headers: _headers,
        ),
      );
    } finally {
      await clearSession();
    }
  }

  static Future<void> clearSession() async {
    token = null;
    role = null;
    username = null;
    userId = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'user_id');
  }

  static Future<Map<String, dynamic>> latest() => _request(
    () => http.get(Uri.parse('${AppConfig.apiUrl}/latest'), headers: _headers),
  );

  static Future<Map<String, dynamic>> me() async {
    final response = await _request(
      () => http.get(Uri.parse('${AppConfig.apiUrl}/me'), headers: _headers),
    );
    userId = response['id'] is num ? (response['id'] as num).toInt() : null;
    return response;
  }

  static Future<Map<String, dynamic>> history({
    String? device,
    String? from,
    String? to,
    int page = 1,
  }) {
    final query = <String, String>{
      'device': ?device,
      'from': ?from,
      'to': ?to,
      'page': '$page',
    };
    final uri = Uri.parse('${AppConfig.apiUrl}/history')
        .replace(queryParameters: query);
    return _request(() => http.get(uri, headers: _headers));
  }

  static Future<Map<String, dynamic>> getStats({
    required String device,
    required String range,
  }) {
    final uri = Uri.parse('${AppConfig.apiUrl}/stats')
        .replace(queryParameters: {'device': device, 'range': range});
    return _request(() => http.get(uri, headers: _headers));
  }

  static Future<Map<String, dynamic>> getSettings() => _request(
    () =>
        http.get(Uri.parse('${AppConfig.apiUrl}/settings'), headers: _headers),
  );

  static Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> data,
  ) => _request(
    () => http.put(
      Uri.parse('${AppConfig.apiUrl}/settings'),
      headers: _headers,
      body: jsonEncode(data),
    ),
  );

  static Future<Map<String, dynamic>> adminUsers() => _request(
    () => http.get(
      Uri.parse('${AppConfig.apiUrl}/admin/users'),
      headers: _headers,
    ),
  );

  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
  }) => _request(
    () => http.post(
      Uri.parse('${AppConfig.apiUrl}/admin/users'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    ),
  );

  static Future<Map<String, dynamic>> updateUser({
    required int id,
    required String username,
    required String email,
    String? password,
    required bool userApproved,
  }) {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'user_approved': userApproved,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    return _request(
      () => http.put(
        Uri.parse('${AppConfig.apiUrl}/admin/users/$id'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  static Future<void> deleteUser(int id) async {
    await _request(
      () => http.delete(
        Uri.parse('${AppConfig.apiUrl}/admin/users/$id'),
        headers: _headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> fillingHistory({
    int page = 1,
    int perPage = 10,
  }) {
    final uri = Uri.parse('${AppConfig.apiUrl}/history/fillings')
        .replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
    return _request(() => http.get(uri, headers: _headers));
  }

  static Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send,
  ) async {
    late final http.Response response;
    try {
      response = await send().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Tidak dapat terhubung ke server (timeout).');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }

    if (response.statusCode == 204) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respons server tidak valid.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  static String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final message = body['message'];
    final errors = body['errors'];
    if (errors is Map) {
      final details = errors.values
          .whereType<List>()
          .expand((messages) => messages.whereType<String>())
          .join('\n');
      if (details.isNotEmpty) return details;
    }
    if (message is String && message.isNotEmpty) return message;
    return 'Permintaan gagal (HTTP $statusCode).';
  }
}
