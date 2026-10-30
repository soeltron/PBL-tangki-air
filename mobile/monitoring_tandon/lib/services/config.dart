class AppConfig {
  static const host =
      String.fromEnvironment('SERVER_HOST', defaultValue: '192.168.1.8');
  static const apiUrl = 'http://$host:8000/api';
  static const mqttTcpPort = 1883; // HP (Android/iOS)
  static const mqttWsPort = 9001; // browser
}