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
  static const mqttUsername = String.fromEnvironment(
    'MQTT_USERNAME',
    defaultValue: 'tandon',
  );
  static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD');

  static String _host = _defaultHost;
  static String get host => _host;
  static bool get isDomain => isDomainHost(_host);
  static String get apiUrl =>
      isDomain ? 'https://$_host/api' : 'http://$_host:$apiPort/api';

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
    if (isDomainHost(host ?? _host)) return 443;
    return isWeb ? mqttWsPort : mqttTcpPort;
  }

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
