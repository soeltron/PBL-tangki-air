import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String server, String clientIdentifier, int port) {
  return MqttServerClient.withPort(server, clientIdentifier, port);
}
