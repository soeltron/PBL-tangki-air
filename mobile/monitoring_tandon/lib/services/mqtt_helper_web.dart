import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(String server, String clientIdentifier, int port) {
  // Web browser connects via WebSockets
  final wsUrl = server.startsWith('ws://') || server.startsWith('wss://')
      ? server
      : 'ws://$server/mqtt';
  return MqttBrowserClient.withPort(wsUrl, clientIdentifier, port);
}
