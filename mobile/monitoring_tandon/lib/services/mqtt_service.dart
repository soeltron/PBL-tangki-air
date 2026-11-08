import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mqtt_client/mqtt_client.dart';

import 'api_service.dart';
import 'config.dart';
import 'mqtt_helper.dart'
    if (dart.library.io) 'mqtt_helper_io.dart'
    if (dart.library.html) 'mqtt_helper_web.dart'
    if (dart.library.js_interop) 'mqtt_helper_web.dart';

class HistoryRecord {
  final DateTime timestamp;
  final double waterLevel;
  final double temperature;
  final bool pumpStatus;
  final bool isFilling;

  HistoryRecord({
    required this.timestamp,
    required this.waterLevel,
    required this.temperature,
    required this.pumpStatus,
    this.isFilling = false,
  });

  String get formattedTime {
    final localTimestamp = timestamp.toLocal();
    final h = localTimestamp.hour.toString().padLeft(2, '0');
    final m = localTimestamp.minute.toString().padLeft(2, '0');
    final s = localTimestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class MqttService extends ChangeNotifier {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;

  MqttService._internal();

  /// Kontrol pompa dari aplikasi baru aktif setelah firmware device 1
  /// subscribe ke topik kontrol. Ubah ke true kalau sudah siap.
  static const bool pumpControlAvailable = false;
  static const _tankCapacityKey = 'tankCapacityLiters';
  static const _pumpMinLevelKey = 'pumpMinLevel';
  static const _pumpMaxLevelKey = 'pumpMaxLevel';

  // IoT State Variables
  double _waterLevel = 0.0;
  double _capacityLiters = 1000.0;
  double _temperature = 0.0;
  bool _isPumpOn = false;
  bool _isLampOn = false;
  bool _isAutoMode = true;
  double _minThreshold = 30.0; // = batas_air di backend
  double _maxThreshold = 95.0; // lokal saja
  double _batasSuhu = 30.0;
  double _batasDebit = 1.0;

  // Data device 2
  double _flowRate = 0.0;
  String _flowStatus = '-';

  DateTime? _lastUpdate;
  String? _lastError;
  bool _hasData = false;
  bool _isConnecting = false;

  // MQTT Connection Settings
  String _brokerHost = AppConfig.host;
  int _brokerPort = AppConfig.mqttPort(isWeb: kIsWeb);
  String _topicTelemetry = 'tandon/data';
  final String _topicConfig = 'tandon/config';
  String _topicControl = 'tandon/pompa/cmd';
  bool _isConnected = false;
  bool _manualDisconnect = false;

  MqttClient? _client;
  Timer? _reconnectTimer;
  final List<HistoryRecord> _historyLogs = [];
  bool _tankSettingsLoaded = false;
  bool _hasLocalMinThreshold = false;

  // Getters
  double get waterLevel => _waterLevel;
  double get waterVolume => (_waterLevel / 100.0) * _capacityLiters;
  double get capacityLiters => _capacityLiters;
  double get temperature => _temperature;
  bool get isPumpOn => _isPumpOn;
  bool get isLampOn => _isLampOn;
  bool get isAutoMode => _isAutoMode;
  double get minThreshold => _minThreshold;
  double get maxThreshold => _maxThreshold;
  double get batasSuhu => _batasSuhu;
  double get batasDebit => _batasDebit;
  double get flowRate => _flowRate;
  String get flowStatus => _flowStatus;
  DateTime? get lastUpdate => _lastUpdate;
  String? get lastError => _lastError;
  bool get hasData => _hasData;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _lastError != null
      ? 'GAGAL'
      : _isConnected
      ? 'TERSAMBUNG'
      : _isConnecting
      ? 'MENGHUBUNGKAN'
      : 'BELUM TERHUBUNG';
  String get brokerHost => _brokerHost;
  int get brokerPort => _brokerPort;
  List<HistoryRecord> get historyLogs => List.unmodifiable(_historyLogs);
  List<HistoryRecord> get fillingLogs =>
      List.unmodifiable(_historyLogs.where((record) => record.isFilling));

  Future<void> loadTankSettings() async {
    if (_tankSettingsLoaded) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      _capacityLiters =
          preferences.getDouble(_tankCapacityKey) ?? _capacityLiters;
      _minThreshold = preferences.getDouble(_pumpMinLevelKey) ?? _minThreshold;
      _maxThreshold = preferences.getDouble(_pumpMaxLevelKey) ?? _maxThreshold;
      _hasLocalMinThreshold = preferences.containsKey(_pumpMinLevelKey);
      _tankSettingsLoaded = true;
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to load tank settings: $error');
    }
  }

  Future<void> saveTankSettings({
    required double capacityLiters,
    required double minLevel,
    required double maxLevel,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_tankCapacityKey, capacityLiters);
    await preferences.setDouble(_pumpMinLevelKey, minLevel);
    await preferences.setDouble(_pumpMaxLevelKey, maxLevel);
    _capacityLiters = capacityLiters;
    _minThreshold = minLevel;
    _maxThreshold = maxLevel;
    _hasLocalMinThreshold = true;
    _tankSettingsLoaded = true;
    notifyListeners();
  }

  // ---------------- State dan kontrol ----------------

  void _addHistoryRecord() {
    _historyLogs.insert(
      0,
      HistoryRecord(
        timestamp: DateTime.now(),
        waterLevel: double.parse(_waterLevel.toStringAsFixed(1)),
        temperature: double.parse(_temperature.toStringAsFixed(1)),
        pumpStatus: _isPumpOn,
        isFilling:
            _isPumpOn ||
            (_historyLogs.isNotEmpty &&
                _waterLevel > _historyLogs.first.waterLevel),
      ),
    );

    if (_historyLogs.length > 50) {
      _historyLogs.removeLast();
    }
  }

  void togglePump() {
    setPump(!_isPumpOn);
  }

  void setPump(bool value) {
    if (!pumpControlAvailable) return;
    // Status pompa diperbarui dari data device (field "pompa").
    publishControlCommand(value ? 'ON' : 'OFF');
  }

  void toggleAutoMode() {
    _isAutoMode = !_isAutoMode;
    notifyListeners();
  }

  /// minVal dikirim ke backend sebagai batas_air; maxVal hanya lokal.
  void setThresholds(double minVal, double maxVal) {
    _minThreshold = minVal;
    _maxThreshold = maxVal;
    notifyListeners();
    saveSettings(batasAir: minVal);
  }

  void setCapacity(double liters) {
    _capacityLiters = liters;
    notifyListeners();
  }

  // ---------------- Konfigurasi ke backend ----------------

  Future<void> loadLatestFromServer() async {
    try {
      final r = await ApiService.latest();
      final d1 = r['d1'];
      final d2 = r['d2'];
      if (d1 is Map<String, dynamic>) {
        final level = _num(d1['level']);
        final suhu = _num(d1['suhu']);
        final pompa = _bool(d1['pompa']);
        if (level != null) _waterLevel = level;
        if (suhu != null) _temperature = suhu;
        if (pompa != null) _isPumpOn = pompa;
        final t = DateTime.tryParse('${d1['created_at']}');
        if (t != null) _lastUpdate = t.toLocal();
        _hasData = true;
      }
      if (d2 is Map<String, dynamic>) {
        final debit = _num(d2['debit']);
        if (debit != null) _flowRate = debit;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load latest error: $e');
    }
  }

  Future<void> loadSettingsFromServer() async {
    try {
      final s = await ApiService.getSettings();
      applyServerSettings(s);
    } catch (e) {
      debugPrint('Load settings error: $e');
    }
  }

  void applyServerSettings(Map<String, dynamic> settings) {
    final air = _num(settings['batas_air']);
    final suhu = _num(settings['batas_suhu']);
    final debit = _num(settings['batas_debit']);
    if (air != null) {
      _minThreshold = air;
      _hasLocalMinThreshold = false;
    }
    if (suhu != null) _batasSuhu = suhu;
    if (debit != null) _batasDebit = debit;
    notifyListeners();
  }

  Future<void> loadHistoryFromServer() async {
    try {
      final r = await ApiService.history(device: 'd1');
      final rows = r['data'];
      if (rows is! List) return;
      final records = rows.whereType<Map<String, dynamic>>().map((row) {
        final t =
            DateTime.tryParse('${row['created_at']}')?.toLocal() ??
            DateTime.now();
        return HistoryRecord(
          timestamp: t,
          waterLevel: _num(row['level']) ?? 0,
          temperature: _num(row['suhu']) ?? 0,
          pumpStatus: _bool(row['pompa']) ?? false,
        );
      }).toList();

      for (var index = 0; index < records.length - 1; index++) {
        final current = records[index];
        final older = records[index + 1];
        if (current.waterLevel > older.waterLevel) {
          records[index] = HistoryRecord(
            timestamp: current.timestamp,
            waterLevel: current.waterLevel,
            temperature: current.temperature,
            pumpStatus: current.pumpStatus,
            isFilling: true,
          );
        }
      }

      _historyLogs
        ..clear()
        ..addAll(records);
      notifyListeners();
    } catch (e) {
      debugPrint('Load history error: $e');
    }
  }

  Future<bool> saveSettings({
    double? batasAir,
    double? batasSuhu,
    double? batasDebit,
  }) async {
    final body = <String, num>{
      'batas_air': ?batasAir,
      'batas_suhu': ?batasSuhu,
      'batas_debit': ?batasDebit,
    };
    if (body.isEmpty) return true;
    try {
      final r = await ApiService.updateSettings(body);
      if (!r.containsKey('batas_air')) return false; // validasi/auth gagal
      final air = _num(r['batas_air']);
      final suhu = _num(r['batas_suhu']);
      final debit = _num(r['batas_debit']);
      if (air != null) _minThreshold = air;
      if (suhu != null) _batasSuhu = suhu;
      if (debit != null) _batasDebit = debit;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Save settings error: $e');
      return false;
    }
  }

  // ---------------- MQTT ----------------

  Future<bool> connectMqtt({
    String? host,
    int? port,
    String? telemetryTopic,
    String? controlTopic,
  }) async {
    if (host != null) {
      _brokerHost = host;
      if (port == null) {
        _brokerPort = AppConfig.mqttPort(isWeb: kIsWeb, host: host);
      }
    }
    if (port != null) _brokerPort = port;
    if (telemetryTopic != null) _topicTelemetry = telemetryTopic;
    if (controlTopic != null) _topicControl = controlTopic;

    if (!AppConfig.hasMqttCredentials) {
      _isConnected = false;
      _isConnecting = false;
      final missing = [
        if (AppConfig.mqttUsername.trim().isEmpty) 'MQTT_USERNAME',
        if (AppConfig.mqttPassword.trim().isEmpty) 'MQTT_PASSWORD',
      ];
      _lastError =
          '${missing.join(' dan ')} kosong. Atur lewat --dart-define atau --dart-define-from-file, lalu jalankan ulang aplikasi.';
      _log('MQTT connection skipped: $_lastError');
      notifyListeners();
      return false;
    }

    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _isConnecting = true;
    _lastError = null;
    _log('Connecting to MQTT broker $_brokerEndpoint');
    notifyListeners();

    // Tutup koneksi lama supaya listener tidak menumpuk.
    final old = _client;
    if (old != null) {
      old.onDisconnected = null;
      old.disconnect();
    }

    final clientIdentifier = 'flutter_tandon_${Random().nextInt(100000)}';

    try {
      _client = createMqttClient(_brokerHost, clientIdentifier, _brokerPort);
      if (kIsWeb) _client!.websocketProtocols = const ['mqtt'];
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = (topic) =>
          _log('MQTT subscribe accepted: $topic');
      _client!.onSubscribeFail = (topic) {
        _lastError = 'Broker menolak subscribe ke topik $topic.';
        _log(_lastError!);
        notifyListeners();
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientIdentifier)
          .authenticateAs(AppConfig.mqttUsername, AppConfig.mqttPassword)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      _client!.connectionMessage = connMessage;

      await _client!.connect();
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _isConnected = true;
        _isConnecting = false;
        _lastError = null;
        _client!.updates?.listen(_onMqttMessage);
        _client!.subscribe(_topicTelemetry, MqttQos.atMostOnce);
        _client!.subscribe(_topicConfig, MqttQos.atLeastOnce);
        _log(
          'Connected to $_brokerEndpoint; subscribed to '
          '$_topicTelemetry and $_topicConfig',
        );
        notifyListeners();
        return true;
      } else {
        _isConnected = false;
        _isConnecting = false;
        final returnCode = _client!.connectionStatus?.returnCode;
        _lastError =
            'Broker menolak koneksi ke $_brokerEndpoint'
            '${returnCode == null ? '.' : ': ${returnCode.name}.'}';
        _log(_lastError!);
        _client!.onDisconnected = null;
        _client!.disconnect();
      }
    } catch (e) {
      _client?.onDisconnected = null;
      _client?.disconnect();
      _isConnected = false;
      _isConnecting = false;
      final reason = _safeConnectionError(e);
      _lastError = 'Koneksi ke $_brokerEndpoint gagal: $reason';
      _log(_lastError!);
    }

    _lastError ??= 'Tidak dapat terhubung ke broker $_brokerEndpoint.';
    _scheduleReconnect();
    notifyListeners();
    return false;
  }

  void disconnectMqtt() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || !AppConfig.hasMqttCredentials) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () => connectMqtt());
  }

  void publishControlCommand(String command) {
    if (_isConnected && _client != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      _client!.publishMessage(
        _topicControl,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    }
  }

  void _onConnected() {
    _isConnected = true;
    _isConnecting = false;
    _lastError = null;
    notifyListeners();
  }

  void _onDisconnected() {
    _isConnected = false;
    _isConnecting = false;
    if (!_manualDisconnect) {
      _lastError = 'Koneksi ke $_brokerEndpoint terputus.';
      _log(_lastError!);
    }
    notifyListeners();
    _scheduleReconnect();
  }

  void _onMqttMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final m in messages) {
      final rec = m.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        rec.payload.message,
      );
      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) continue;
        _log(
          'MQTT message received: topic=${m.topic}, device=${decoded['device']}',
        );
        if (m.topic == _topicConfig) {
          _handleConfig(decoded);
        } else if (m.topic == _topicTelemetry) {
          _handleTelemetry(decoded);
        }
      } catch (e) {
        debugPrint('Parse payload error: $e');
      }
    }
    notifyListeners();
  }

  String get _brokerEndpoint {
    if (kIsWeb) {
      final secure = AppConfig.isDomainHost(_brokerHost);
      return '${secure ? 'wss' : 'ws'}://$_brokerHost:$_brokerPort/mqtt';
    }
    return '$_brokerHost:$_brokerPort';
  }

  String _safeConnectionError(Object error) {
    var reason = error.toString();
    for (final secret in [AppConfig.mqttUsername, AppConfig.mqttPassword]) {
      if (secret.isNotEmpty) reason = reason.replaceAll(secret, '[redacted]');
    }
    return reason.length > 180 ? '${reason.substring(0, 180)}…' : reason;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  void _handleConfig(Map<String, dynamic> d) {
    final air = _num(d['batas_air']);
    final suhu = _num(d['batas_suhu']);
    final debit = _num(d['batas_debit']);
    if (air != null && !_hasLocalMinThreshold) _minThreshold = air;
    if (suhu != null) _batasSuhu = suhu;
    if (debit != null) _batasDebit = debit;
  }

  void _handleTelemetry(Map<String, dynamic> d) {
    final device = d['device'];
    if (device == 'd1') {
      final level = _num(d['level']);
      final suhu = _num(d['suhu']);
      final pompa = _bool(d['pompa']);
      final lampu = _bool(d['lampu']);
      if (level != null) _waterLevel = level;
      if (suhu != null) _temperature = suhu;
      if (pompa != null) _isPumpOn = pompa;
      if (lampu != null) _isLampOn = lampu;
      _hasData = true;
      _lastUpdate = DateTime.now();
      _addHistoryRecord();
    } else if (device == 'd2') {
      final debit = _num(d['debit']);
      final status = d['status'];
      if (debit != null) _flowRate = debit;
      if (status is String) _flowStatus = status;
      _lastUpdate = DateTime.now();
    }
  }

  double? _num(dynamic v) => v is num ? v.toDouble() : null;

  bool? _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return null;
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    super.dispose();
  }
}
