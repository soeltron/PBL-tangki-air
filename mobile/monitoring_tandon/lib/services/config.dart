import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _hostKey = 'serverHost';
  static const _defaultHost = String.fromEnvironment(
    'SERVER_HOST',
    defaultValue: 'localhost',
  );
  static const apiPort = 8000;
  static const mqttTcpPort = 1883;
  static const mqttUsername = String.fromEnvironment(
    'MQTT_USERNAME',
    defaultValue: '',
  );
  static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD');
  static bool get hasMqttCredentials =>
      mqttUsername.trim().isNotEmpty && mqttPassword.trim().isNotEmpty;

  static String _host = _defaultHost;
  static String get host => _host;
  static bool get hasServerHost => _host.trim().isNotEmpty;
  static bool get isDomain => isDomainHost(_host);
  static String get apiUrl => apiUri().toString();

  static Uri apiUri({String? host}) {
    final server = host ?? _host;
    final domain = isDomainHost(server);
    return Uri(
      scheme: domain ? 'https' : 'http',
      host: server,
      port: domain ? null : apiPort,
      path: '/api',
    );
  }

  static Uri mqttUri({required bool isWeb, String? host}) {
    final server = host ?? _host;
    if (!isWeb) {
      return Uri(scheme: 'mqtt', host: server, port: mqttTcpPort);
    }

    final secure = isDomainHost(server);
    return Uri(
      scheme: secure ? 'wss' : 'ws',
      host: server,
      port: secure ? 443 : apiPort,
      path: '/mqtt',
    );
  }

  static bool isDomainHost(String host) {
    if (!host.contains('.') || host.contains(':')) return false;
    final parts = host.split('.');
    final isIpv4 =
        parts.length == 4 &&
        parts.every((part) {
          final octet = int.tryParse(part);
          return octet != null && octet >= 0 && octet <= 255;
        });
    return !isIpv4;
  }

  static int mqttPort({required bool isWeb, String? host}) {
    return mqttUri(isWeb: isWeb, host: host).port;
  }

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _host = (preferences.getString(_hostKey) ?? _defaultHost).trim();
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
