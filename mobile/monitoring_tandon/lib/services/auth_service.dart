import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';
import 'mqtt_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage();

  bool _isLoggedIn = false;
  String _username = '';
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String? get error => _error;

  /// Panggil sekali di main() sebelum runApp: pulihkan sesi dari token.
  Future<void> init() async {
    await ApiService.loadToken();
    if (ApiService.token == null) return;

    var valid = true;
    try {
      final s = await ApiService.getSettings();
      valid = s.containsKey('batas_air'); // token ditolak -> tidak ada field ini
    } catch (_) {
      valid = true; // server tidak terjangkau, tetap anggap sudah login
    }

    if (valid) {
      _isLoggedIn = true;
      _username = await _storage.read(key: 'username') ?? 'Pengguna';
      _startServices();
    } else {
      await ApiService.logout();
    }
    notifyListeners();
  }

  /// Login ke backend. "user" berisi EMAIL akun (mis. admin@mail.com).
  Future<bool> login(String user, String pass) async {
    _error = null;
    try {
      final ok = await ApiService.login(user.trim(), pass);
      if (!ok) {
        _error = 'Email atau password salah';
        notifyListeners();
        return false;
      }
      _isLoggedIn = true;
      _username = user.trim();
      await _storage.write(key: 'username', value: _username);
      _startServices();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tidak dapat terhubung ke server';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    MqttService().disconnectMqtt();
    await ApiService.logout();
    await _storage.delete(key: 'username');
    _isLoggedIn = false;
    _username = '';
    notifyListeners();
  }

  void _startServices() {
  final mqtt = MqttService();
  mqtt.loadSettingsFromServer();
  mqtt.loadLatestFromServer();
  mqtt.loadHistoryFromServer();
  mqtt.connectMqtt();
  }
}