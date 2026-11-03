import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _hostKey = 'serverHost';
  static const _defaultHost = String.fromEnvironment(
    'SERVER_HOST',
    defaultValue: '192.168.1.7',
  );
  static const apiPort = 8000;
  static const mqttTcpPort = 1883;
  static const mqttWsPort = 9001;
  static const mqttUsername = 'tandon';
  static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD');

  static String _host = _defaultHost;
  static String get host => _host;
  static String get apiUrl => 'http://$_host:$apiPort/api';

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _host = preferences.getString(_hostKey) ?? _defaultHost;
  }

  static Future<void> setHost(String value) async {
    final host = value.trim();
    final parsedHost = Uri.tryParse('http://$host');
    if (host.isEmpty ||
        host.contains(RegExp(r'[\s/@?#]')) ||
        parsedHost == null ||
        parsedHost.host.isEmpty ||
        parsedHost.hasPort) {
      throw const FormatException('Host server tidak valid.');
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_hostKey, host);
    _host = host;
  }
}
