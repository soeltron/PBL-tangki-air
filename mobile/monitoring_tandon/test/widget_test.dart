import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_tandon/services/config.dart';

void main() {
  group('AppConfig API URLs', () {
    test('uses HTTP and the API port for localhost and IP addresses', () {
      expect(
        AppConfig.apiUri(host: 'localhost').toString(),
        'http://localhost:8000/api',
      );
      expect(
        AppConfig.apiUri(host: '192.168.1.25').toString(),
        'http://192.168.1.25:8000/api',
      );
    });

    test('uses HTTPS without an explicit port for domain hosts', () {
      expect(
        AppConfig.apiUri(host: 'api.example.com').toString(),
        'https://api.example.com/api',
      );
    });
  });

  group('AppConfig MQTT URLs', () {
    test(
      'uses the HTTP host port and one /mqtt path for web on localhost/IP',
      () {
        expect(
          AppConfig.mqttUri(isWeb: true, host: 'localhost').toString(),
          'ws://localhost:8000/mqtt',
        );
        expect(
          AppConfig.mqttUri(isWeb: true, host: '192.168.1.25').toString(),
          'ws://192.168.1.25:8000/mqtt',
        );
        expect(AppConfig.mqttPort(isWeb: true, host: 'localhost'), 8000);
        expect(AppConfig.mqttPort(isWeb: true, host: '192.168.1.25'), 8000);
      },
    );

    test('uses secure WebSocket on port 443 for web domain hosts', () {
      expect(
        AppConfig.mqttUri(isWeb: true, host: 'broker.example.com').toString(),
        'wss://broker.example.com:443/mqtt',
      );
      expect(AppConfig.mqttPort(isWeb: true, host: 'broker.example.com'), 443);
    });

    test('uses native MQTT TCP on port 1883 for localhost, IP, and domain', () {
      for (final host in ['localhost', '192.168.1.25', 'broker.example.com']) {
        expect(
          AppConfig.mqttUri(isWeb: false, host: host).toString(),
          'mqtt://$host:1883',
        );
        expect(AppConfig.mqttPort(isWeb: false, host: host), 1883);
      }
    });
  });
}
