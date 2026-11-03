import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/theme_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _device = 'd1';
  String _range = '24h';
  List<Map<String, dynamic>> _points = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getStats(
        device: _device,
        range: _range,
      );
      final rawPoints = response['points'];
      if (rawPoints is! List) {
        throw const FormatException('Data statistik server tidak valid.');
      }

      final rawSummary = response['summary'];
      if (!mounted) return;
      setState(() {
        _points = rawPoints.whereType<Map<String, dynamic>>().toList();
        _summary = rawSummary is Map<String, dynamic> ? rawSummary : {};
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(isDark, textColor),
          const SizedBox(height: 18),
          Text(
            'Ringkasan $_device',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildSummary(isDark, textColor, secondaryColor),
          const SizedBox(height: 22),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildMessage(
              icon: Icons.cloud_off_rounded,
              message: _error!,
              textColor: textColor,
              action: TextButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            )
          else if (_points.isEmpty)
            _buildMessage(
              icon: Icons.bar_chart_rounded,
              message: 'Belum ada data untuk rentang ini.',
              textColor: textColor,
            )
          else ...[
            Text(
              'Grafik per Jam',
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _MetricChart(
              title: 'Level Air',
              unit: '%',
              prefix: 'level',
              points: _points,
              range: _range,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _MetricChart(
              title: 'Suhu',
              unit: '°C',
              prefix: 'suhu',
              points: _points,
              range: _range,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _MetricChart(
              title: 'Debit',
              unit: 'L/menit',
              prefix: 'debit',
              points: _points,
              range: _range,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark, Color textColor) {
    final borderColor = isDark
        ? const Color(0xFF24324A)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perangkat',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'd1', label: Text('Tandon d1')),
              ButtonSegment(value: 'd2', label: Text('Tandon d2')),
            ],
            selected: {_device},
            onSelectionChanged: (selection) {
              setState(() => _device = selection.first);
              _loadStats();
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Rentang waktu',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '24h', label: Text('24 jam')),
              ButtonSegment(value: '7d', label: Text('7 hari')),
            ],
            selected: {_range},
            onSelectionChanged: (selection) {
              setState(() => _range = selection.first);
              _loadStats();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(bool isDark, Color textColor, Color secondaryColor) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - 44) / 2;
    const metrics = [
      ('Level Air', 'level', '%'),
      ('Suhu', 'suhu', '°C'),
      ('Debit', 'debit', 'L/m'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (label, prefix, unit) in metrics)
          SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF24324A)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SummaryValue(
                    label: 'Rata-rata',
                    value: _summary['avg_$prefix'],
                    unit: unit,
                    color: secondaryColor,
                  ),
                  _SummaryValue(
                    label: 'Minimum',
                    value: _summary['min_$prefix'],
                    unit: unit,
                    color: secondaryColor,
                  ),
                  _SummaryValue(
                    label: 'Maksimum',
                    value: _summary['max_$prefix'],
                    unit: unit,
                    color: secondaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    required Color textColor,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 42, color: const Color(0xFF0284C7)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final dynamic value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final number = value is num ? (value as num).toStringAsFixed(1) : '-';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$label: $number $unit',
        style: TextStyle(color: color, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MetricChart extends StatelessWidget {
  const _MetricChart({
    required this.title,
    required this.unit,
    required this.prefix,
    required this.points,
    required this.range,
    required this.isDark,
  });

  final String title;
  final String unit;
  final String prefix;
  final List<Map<String, dynamic>> points;
  final String range;
  final bool isDark;

  static const _series = [
    ('Rata-rata', 'avg', Color(0xFF0284C7)),
    ('Minimum', 'min', Color(0xFF16A34A)),
    ('Maksimum', 'max', Color(0xFFF97316)),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final spots = [
      for (final (_, key, _) in _series) _makeSpots('${key}_$prefix'),
    ];
    final allValues = spots.expand((series) => series).map((spot) => spot.y);

    if (allValues.isEmpty) {
      return _chartCard(
        textColor,
        secondaryColor,
        const SizedBox(
          height: 190,
          child: Center(child: Text('Belum ada data untuk parameter ini.')),
        ),
      );
    }

    final lowest = allValues.reduce(math.min);
    final highest = allValues.reduce(math.max);
    final padding = math.max((highest - lowest) * 0.12, 1.0);
    final minY = lowest - padding;
    final maxY = highest + padding;
    final interval = (maxY - minY) / 4;
    final lineBars = <LineChartBarData>[];
    final visibleColors = <Color>[];

    for (var index = 0; index < _series.length; index++) {
      if (spots[index].isEmpty) continue;
      visibleColors.add(_series[index].$3);
      lineBars.add(
        LineChartBarData(
          spots: spots[index],
          color: _series[index].$3,
          isCurved: true,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return _chartCard(
      textColor,
      secondaryColor,
      Column(
        children: [
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1.0, points.length - 1.0),
                minY: minY,
                maxY: maxY,
                lineBarsData: lineBars,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? const Color(0xFF24324A)
                        : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: interval,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(color: secondaryColor, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _xInterval(),
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatHour(points[index]['hour']),
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit',
                            TextStyle(
                              color: visibleColors[spot.barIndex],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              for (final (label, _, color) in _series)
                _LegendItem(
                  label: label,
                  color: color,
                  textColor: secondaryColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartCard(Color textColor, Color secondaryColor, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title ($unit)',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  List<FlSpot> _makeSpots(String key) => [
    for (var index = 0; index < points.length; index++)
      if (points[index][key] is num)
        FlSpot(index.toDouble(), (points[index][key] as num).toDouble()),
  ];

  double _xInterval() {
    final maxLabels = range == '7d' ? 7 : 6;
    return math.max(1.0, (points.length - 1) / maxLabels);
  }

  String _formatHour(dynamic value) {
    final date = DateTime.parse(value.toString());
    if (range == '7d') return '${date.day}/${date.month}';
    return '${date.hour.toString().padLeft(2, '0')}:00';
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: textColor, fontSize: 10)),
      ],
    );
  }
}
