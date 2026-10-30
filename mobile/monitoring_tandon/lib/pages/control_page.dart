import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../services/theme_service.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final mqttService = MqttService();
  final themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    mqttService.addListener(_onUpdate);
    themeService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    mqttService.removeListener(_onUpdate);
    themeService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final isAuto = mqttService.isAutoMode;
    final pumpOn = mqttService.isPumpOn;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final card = isDark ? const Color(0xFF131C2E) : Colors.white;
    final border = isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(Icons.autorenew_rounded, color: accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Pompa Otomatis',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pompa hidup pada level ${mqttService.minThreshold.toStringAsFixed(0)}% '
                      'dan mati pada ${mqttService.maxThreshold.toStringAsFixed(0)}%.',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAuto,
                activeThumbColor: accent,
                onChanged: (_) => mqttService.toggleAutoMode(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Mode otomatis pada layar ini belum mengirim perintah ke pompa fisik. '
            'Perlu dukungan firmware perangkat untuk kontrol langsung.',
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Text(
                'STATUS POMPA',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              Icon(
                pumpOn
                    ? Icons.water_drop_rounded
                    : Icons.power_settings_new_rounded,
                size: 56,
                color: pumpOn ? Colors.green : textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                pumpOn ? 'MENYALA' : 'MATI',
                style: TextStyle(
                  color: pumpOn ? Colors.green : textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Level air: ${mqttService.waterLevel.toStringAsFixed(1)}%',
                style: TextStyle(color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
