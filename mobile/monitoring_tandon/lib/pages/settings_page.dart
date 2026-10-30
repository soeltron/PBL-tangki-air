import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _capacityController;
  late final TextEditingController _maxLevelController;
  late final TextEditingController _minLevelController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    mqttService.addListener(_onUpdate);
    themeService.addListener(_onUpdate);
    _capacityController = TextEditingController(
      text: mqttService.capacityLiters.toStringAsFixed(0),
    );
    _maxLevelController = TextEditingController(
      text: mqttService.maxThreshold.toStringAsFixed(0),
    );
    _minLevelController = TextEditingController(
      text: mqttService.minThreshold.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    mqttService.removeListener(_onUpdate);
    themeService.removeListener(_onUpdate);
    _capacityController.dispose();
    _maxLevelController.dispose();
    _minLevelController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
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

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await mqttService.saveTankSettings(
        capacityLiters: double.parse(_capacityController.text),
        minLevel: double.parse(_minLevelController.text),
        maxLevel: double.parse(_maxLevelController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan tandon tersimpan di perangkat.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengaturan gagal disimpan: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Form(
            key: _formKey,
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
                  'Pengaturan disimpan di perangkat ini. Kontrol pompa fisik '
                  'memerlukan dukungan firmware.',
                  style: TextStyle(color: secondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                _numberField(
                  controller: _capacityController,
                  label: 'Kapasitas tangki (liter)',
                  validator: _validateCapacity,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _maxLevelController,
                  label: 'Level maksimum — pompa mati (%)',
                  validator: (value) => _validateLevel(value, isMinimum: false),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _minLevelController,
                  label: 'Level minimum — pompa menyala (%)',
                  validator: (value) => _validateLevel(value, isMinimum: true),
                  isDark: isDark,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan Pengaturan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
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
