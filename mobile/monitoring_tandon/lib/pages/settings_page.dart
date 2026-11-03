import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/config.dart';
import '../services/mqtt_service.dart';
import '../services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final mqttService = MqttService();
  final themeService = ThemeService();
  final authService = AuthService();
  final _localFormKey = GlobalKey<FormState>();
  final _limitsFormKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _capacityController;
  late final TextEditingController _maxLevelController;
  late final TextEditingController _minLevelController;
  late final TextEditingController _waterLimitController;
  late final TextEditingController _temperatureLimitController;
  late final TextEditingController _flowLimitController;
  bool _isSavingLocal = false;
  bool _isSavingHost = false;
  bool _isSavingLimits = false;

  @override
  void initState() {
    super.initState();
    mqttService.addListener(_onUpdate);
    themeService.addListener(_onUpdate);
    _hostController = TextEditingController(text: AppConfig.host);
    _capacityController = TextEditingController(
      text: mqttService.capacityLiters.toStringAsFixed(0),
    );
    _maxLevelController = TextEditingController(
      text: mqttService.maxThreshold.toStringAsFixed(0),
    );
    _minLevelController = TextEditingController(
      text: mqttService.minThreshold.toStringAsFixed(0),
    );
    _waterLimitController = TextEditingController();
    _temperatureLimitController = TextEditingController();
    _flowLimitController = TextEditingController();
    _loadServerSettings();
  }

  @override
  void dispose() {
    mqttService.removeListener(_onUpdate);
    themeService.removeListener(_onUpdate);
    _hostController.dispose();
    _capacityController.dispose();
    _maxLevelController.dispose();
    _minLevelController.dispose();
    _waterLimitController.dispose();
    _temperatureLimitController.dispose();
    _flowLimitController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadServerSettings() async {
    try {
      final settings = await ApiService.getSettings();
      if (!mounted) return;
      setState(() {
        _waterLimitController.text = '${settings['batas_air'] ?? ''}';
        _temperatureLimitController.text = '${settings['batas_suhu'] ?? ''}';
        _flowLimitController.text = '${settings['batas_debit'] ?? ''}';
      });
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  String? _validateCapacity(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return 'Masukkan kapasitas lebih dari 0 liter';
    }
    return null;
  }

  String? _validateLevel(String? value, {required bool isMinimum}) {
    final number = double.tryParse(value ?? '');
    if (number == null || number < 0 || number > 100) {
      return 'Masukkan nilai antara 0 dan 100';
    }
    final otherValue = double.tryParse(
      isMinimum ? _maxLevelController.text : _minLevelController.text,
    );
    if (otherValue != null &&
        (isMinimum ? number >= otherValue : number <= otherValue)) {
      return isMinimum
          ? 'Level minimum harus lebih rendah dari maksimum'
          : 'Level maksimum harus lebih tinggi dari minimum';
    }
    return null;
  }

  String? _validatePercent(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null || number < 0 || number > 100) {
      return 'Masukkan nilai antara 0 dan 100';
    }
    return null;
  }

  String? _validateNonnegative(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null || number < 0) {
      return 'Masukkan nilai 0 atau lebih';
    }
    return null;
  }

  Future<void> _saveHost() async {
    setState(() => _isSavingHost = true);
    try {
      await AppConfig.setHost(_hostController.text);
      await mqttService.connectMqtt(
        host: AppConfig.host,
        port: kIsWeb ? AppConfig.mqttWsPort : AppConfig.mqttTcpPort,
      );
      if (mounted) _showMessage('Host server berhasil disimpan.');
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSavingHost = false);
    }
  }

  Future<void> _saveLocalSettings() async {
    if (!authService.isAdmin || !_localFormKey.currentState!.validate()) return;

    setState(() => _isSavingLocal = true);
    try {
      await mqttService.saveTankSettings(
        capacityLiters: double.parse(_capacityController.text),
        minLevel: double.parse(_minLevelController.text),
        maxLevel: double.parse(_maxLevelController.text),
      );
      if (mounted) _showMessage('Pengaturan tandon tersimpan di perangkat.');
    } catch (error) {
      if (mounted) _showMessage('Pengaturan gagal disimpan: $error');
    } finally {
      if (mounted) setState(() => _isSavingLocal = false);
    }
  }

  Future<void> _saveLimits() async {
    if (!authService.isAdmin || !_limitsFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSavingLimits = true);
    try {
      final settings = await ApiService.updateSettings({
        'batas_air': double.parse(_waterLimitController.text),
        'batas_suhu': double.parse(_temperatureLimitController.text),
        'batas_debit': double.parse(_flowLimitController.text),
      });
      mqttService.applyServerSettings(settings);
      if (mounted) _showMessage('Batas pengaturan berhasil diperbarui.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSavingLimits = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final card = isDark ? const Color(0xFF131C2E) : Colors.white;
    final border = isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0);
    final primary = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          card: card,
          border: border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Koneksi Server',
                style: TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan IP WiFi laptop atau hostname server.',
                style: TextStyle(color: secondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hostController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Host (tanpa protokol/port)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingHost ? null : _saveHost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  child: _isSavingHost
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Simpan Host'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          card: card,
          border: border,
          child: Form(
            key: _localFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kapasitas dan Ambang Pompa',
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pengaturan lokal perangkat. Kontrol pompa fisik '
                  'memerlukan dukungan firmware.',
                  style: TextStyle(color: secondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                _numberField(
                  controller: _capacityController,
                  label: 'Kapasitas tangki (liter)',
                  validator: _validateCapacity,
                  isDark: isDark,
                  enabled: authService.isAdmin,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _maxLevelController,
                  label: 'Level maksimum — pompa mati (%)',
                  validator: (value) => _validateLevel(value, isMinimum: false),
                  isDark: isDark,
                  enabled: authService.isAdmin,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _minLevelController,
                  label: 'Level minimum — pompa menyala (%)',
                  validator: (value) => _validateLevel(value, isMinimum: true),
                  isDark: isDark,
                  enabled: authService.isAdmin,
                ),
                if (authService.isAdmin) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingLocal ? null : _saveLocalSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSavingLocal
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text('Simpan Pengaturan Lokal'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _card(
          card: card,
          border: border,
          child: Form(
            key: _limitsFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batas Sistem',
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  authService.isAdmin
                      ? 'Batas ini disimpan di server dan diterbitkan melalui MQTT.'
                      : 'Batas server (hanya-baca).',
                  style: TextStyle(color: secondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                _numberField(
                  controller: _waterLimitController,
                  label: 'Batas air (%)',
                  validator: _validatePercent,
                  isDark: isDark,
                  enabled: authService.isAdmin,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _temperatureLimitController,
                  label: 'Batas suhu (°C)',
                  validator: _validatePercent,
                  isDark: isDark,
                  enabled: authService.isAdmin,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _flowLimitController,
                  label: 'Batas debit',
                  validator: _validateNonnegative,
                  isDark: isDark,
                  enabled: authService.isAdmin,
                ),
                if (authService.isAdmin) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingLimits ? null : _saveLimits,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSavingLimits
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text('Simpan Batas Server'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required Color card,
    required Color border,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool isDark,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF0D1424) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
