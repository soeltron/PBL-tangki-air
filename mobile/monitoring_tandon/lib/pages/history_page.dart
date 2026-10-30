import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/mqtt_service.dart';
import '../services/theme_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final mqttService = MqttService();
  final themeService = ThemeService();
  static const _historyLimitKey = 'historyDisplayLimit';
  int _historyLimit = 20;

  @override
  void initState() {
    super.initState();
    mqttService.addListener(_onMqttUpdate);
    themeService.addListener(_onMqttUpdate);
    _loadHistoryLimit();
  }

  @override
  void dispose() {
    mqttService.removeListener(_onMqttUpdate);
    themeService.removeListener(_onMqttUpdate);
    super.dispose();
  }

  void _onMqttUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHistoryLimit() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getInt(_historyLimitKey);
      if ([10, 20, 50].contains(value) && mounted) {
        setState(() => _historyLimit = value!);
      }
    } catch (error) {
      debugPrint('Failed to load history display limit: $error');
    }
  }

  Future<void> _saveHistoryLimit(int value) async {
    setState(() => _historyLimit = value);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_historyLimitKey, value);
    } catch (error) {
      debugPrint('Failed to save history display limit: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jumlah riwayat: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = mqttService.historyLogs.take(_historyLimit).toList();
    final fillingLogs = mqttService.fillingLogs.take(_historyLimit).toList();
    final isDark = themeService.isDarkMode;

    final cardBg = isDark ? const Color(0xFF131C2E) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF24324A)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF0284C7);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah riwayat ditampilkan',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _historyLimit,
                items: const [10, 20, 50]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count data'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) _saveHistoryLimit(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chart Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Grafik Tren Level Air (%)',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _HistoryChartPainter(logs: logs, isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Log Records List
          Text(
            'Catatan Telemetri Real-Time',
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Text(
                'Belum ada data riwayat telemetri',
                style: TextStyle(color: textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.formattedTime,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${log.waterLevel.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.thermostat_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${log.temperature.toStringAsFixed(1)} °C',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Text(
            'Riwayat Pengisian Air',
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (fillingLogs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Text(
                'Belum terdeteksi kenaikan level air.',
                style: TextStyle(color: textSecondary),
              ),
            )
          else
            ...fillingLogs.map(
              (record) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.water_drop_rounded, color: accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTimestamp(record.timestamp),
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Level ${record.waterLevel.toStringAsFixed(1)}% • '
                            'Suhu ${record.temperature.toStringAsFixed(1)} °C',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final time = value.toLocal();
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$day/$month/${time.year} $hour:$minute:$second';
  }
}

class _HistoryChartPainter extends CustomPainter {
  final List<HistoryRecord> logs;
  final bool isDark;

  _HistoryChartPainter({required this.logs, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0))
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = (height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final recentLogs = logs.take(15).toList().reversed.toList();
    if (recentLogs.length < 2) return;

    final List<Offset> points = [];
    final double stepX = width / (recentLogs.length - 1);

    for (int i = 0; i < recentLogs.length; i++) {
      final double level = recentLogs[i].waterLevel.clamp(0.0, 100.0);
      final double x = i * stepX;
      final double y =
          height - ((level / 100.0) * height * 0.8) - (height * 0.1);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF0284C7);

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    final endPoint = points.last;
    final outerDotPaint = Paint()..color = accentColor.withValues(alpha: 0.25);
    final innerDotPaint = Paint()..color = accentColor;

    canvas.drawCircle(endPoint, 7, outerDotPaint);
    canvas.drawCircle(endPoint, 4, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) {
    return oldDelegate.logs.length != logs.length ||
        oldDelegate.isDark != isDark ||
        (logs.isNotEmpty &&
            oldDelegate.logs.isNotEmpty &&
            oldDelegate.logs.first.waterLevel != logs.first.waterLevel);
  }
}
