import 'package:flutter/material.dart';

import 'api_service.dart';
import 'mqtt_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String _username = '';
  String _role = 'user';
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _role == 'admin';
  String get username => _username;
  String get role => _role;
  String? get error => _error;

  Future<void> init() async {
    await ApiService.loadToken();
    if (ApiService.token == null) return;

    try {
      await ApiService.getSettings();
      await ApiService.me();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ApiService.clearSession();
        return;
      }
    }

    _isLoggedIn = true;
    _username = ApiService.username ?? 'Pengguna';
    _role = ApiService.role ?? 'user';
    _startServices();
    notifyListeners();
  }

  Future<bool> login(String login, String pass) async {
    _error = null;
    try {
      await ApiService.login(login.trim(), pass);
      _isLoggedIn = true;
      _username = ApiService.username ?? login.trim();
      _role = ApiService.role ?? 'user';
      _startServices();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
    } on FormatException catch (error) {
      _error = error.message;
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    MqttService().disconnectMqtt();
    try {
      await ApiService.logout();
    } finally {
      _isLoggedIn = false;
      _username = '';
      _role = 'user';
      notifyListeners();
    }
  }

  void _startServices() {
    final mqtt = MqttService();
    mqtt.loadSettingsFromServer();
    mqtt.loadLatestFromServer();
    mqtt.loadHistoryFromServer();
    mqtt.connectMqtt();
  }
}
