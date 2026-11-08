import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

import 'config.dart';

MqttClient createMqttClient(String server, String clientIdentifier, int port) {
  final uri = AppConfig.mqttUri(isWeb: true, host: server);
  return MqttBrowserClient.withPort(uri.toString(), clientIdentifier, port);
}
