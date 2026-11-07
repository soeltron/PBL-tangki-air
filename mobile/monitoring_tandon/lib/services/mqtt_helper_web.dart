import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(
  String server,
  String clientIdentifier,
  int port, {
  required bool useWebSocket,
}) {
  final wsUrl = server.startsWith('ws://') || server.startsWith('wss://')
      ? server
      : useWebSocket
      ? 'wss://$server/mqtt'
      : 'ws://$server';
  return MqttBrowserClient.withPort(wsUrl, clientIdentifier, port);
}
