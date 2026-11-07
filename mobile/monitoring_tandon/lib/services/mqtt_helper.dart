import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(
  String server,
  String clientIdentifier,
  int port, {
  required bool useWebSocket,
}) {
  throw UnsupportedError(
    'Cannot create MQTT client without platform implementation',
  );
}
