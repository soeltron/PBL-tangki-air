import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(
  String server,
  String clientIdentifier,
  int port, {
  required bool useWebSocket,
}) {
  final client = MqttServerClient.withPort(
    useWebSocket ? 'wss://$server/mqtt' : server,
    clientIdentifier,
    port,
  );
  // WSS provides TLS; MqttServerClient.secure is for TLS over TCP and disables WebSockets.
  client.useWebSocket = useWebSocket;
  return client;
}
