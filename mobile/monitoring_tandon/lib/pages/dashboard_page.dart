import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/mqtt_service.dart';
import '../services/theme_service.dart';
import '../widgets/tank_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final mqttService = MqttService();
  final themeService = ThemeService();
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    mqttService.addListener(_onMqttUpdate);
    themeService.addListener(_onMqttUpdate);
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

  @override
  Widget build(BuildContext context) {
    final waterLevel = mqttService.waterLevel;
    final capacity = mqttService.capacityLiters;
    final volume = mqttService.waterVolume;
    final temp = mqttService.temperature;
    final isPumpOn = mqttService.isPumpOn;
    final isAuto = mqttService.isAutoMode;
    final isDark = themeService.isDarkMode;
    final username = AuthService().username.isNotEmpty
        ? AuthService().username
        : 'Pengguna';

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
          // 1. TOP HERO BANNER CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF16233B), const Color(0xFF0F172A)]
                    : [const Color(0xFF084B83), const Color(0xFF022B42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DASHBOARD MONITORING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Selamat Datang, ${username.toUpperCase()}! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: const Text(
                        'Semangat belajar dan pantau semua progres tandon air & suhu kamu di sini.',
                        style: TextStyle(
                          color: Color(0xFFBAE6FD),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. PRIORITAS TASK / ALERT CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRIORITAS: KONTROL',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAuto
                                  ? 'Kontrol otomatis: AKTIF'
                                  : 'Kontrol otomatis: NONAKTIF',
                              style: TextStyle(
                                color: isAuto ? Colors.green : Colors.grey,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status Tandon Air & Pompa',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level Air: ${waterLevel.toStringAsFixed(1)}% | Status Pompa: ${isPumpOn ? "MENYALA" : "MATI"}',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    mqttService.togglePump();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPumpOn ? 'Matikan ->' : 'Nyalakan ->',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. TAB SELECTOR BAR
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    0,
                    Icons.menu_book_rounded,
                    'Overview Tandon',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    1,
                    Icons.history_toggle_off_rounded,
                    'Timeline Telemetri',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    2,
                    Icons.sensors_rounded,
                    'Sensor IoT',
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. MAIN CONTENT SECTION BASED ON SELECTED TAB
          if (_activeTab == 0) ...[
            // Central Tank Visual
            Center(
              child: TankView(
                waterLevel: waterLevel,
                capacityLiters: capacity,
                isPumpOn: isPumpOn,
              ),
            ),
            const SizedBox(height: 20),

            // Header "Daftar Tandon / Parameter IoT"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.crop_square_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daftar Parameter Tandon',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '8 Parameter',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildCourseStyleCard(
                  code: 'TKK130801',
                  title: 'LEVEL AIR TANDON',
                  value: '${waterLevel.toStringAsFixed(1)} %',
                  icon: Icons.water_drop_outlined,
                  accentColor: accentColor,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                _buildCourseStyleCard(
                  code: 'TKK130802',
                  title: 'VOLUME AIR',
                  value: '${volume.toStringAsFixed(0)} Liters',
                  icon: Icons.opacity_outlined,
                  accentColor: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0369A1),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                _buildCourseStyleCard(
                  code: 'TKK130803',
                  title: 'SUHU AIR TANDON',
                  value: '${temp.toStringAsFixed(1)} °C',
                  icon: Icons.thermostat_outlined,
                  accentColor: Colors.amber,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                _buildCourseStyleCard(
                  code: 'TKK130804',
                  title: 'STATUS POMPA AIR',
                  value: isPumpOn ? 'MENYALA' : 'MATI',
                  icon: Icons.power_settings_new_outlined,
                  accentColor: isPumpOn ? Colors.green : Colors.redAccent,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                _buildCourseStyleCard(
                  code: 'TKK130806',
                  title: 'MODE KONTROL',
                  value: isAuto ? 'OTOMATIS' : 'MANUAL',
                  icon: Icons.tune_outlined,
                  accentColor: accentColor,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                _buildCourseStyleCard(
                  code: 'TKK130807',
                  title: 'KAPASITAS MAX',
                  value: '${capacity.toInt()} Liters',
                  icon: Icons.format_list_numbered_outlined,
                  accentColor: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0369A1),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                _buildCourseStyleCard(
                  code: 'TKK130808',
                  title: 'STATUS BROKER',
                  value: mqttService.isRealConnected ? 'ONLINE' : 'SIMULASI',
                  icon: Icons.wifi_outlined,
                  accentColor: mqttService.isRealConnected
                      ? Colors.green
                      : Colors.orange,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
              ],
            ),
          ] else if (_activeTab == 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Log Real-Time',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...mqttService.historyLogs
                      .take(10)
                      .map(
                        (log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log.formattedTime,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${log.waterLevel}%',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${log.temperature} °C',
                                style: TextStyle(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Sensor IoT ESP32 / Water Level',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Sensor Ultrasonik HC-SR04 untuk pengukuran ketinggian air.',
                    style: TextStyle(color: textSecondary),
                  ),
                  Text(
                    '• Sensor Suhu DS18B20 Waterproof untuk monitoring suhu tandon.',
                    style: TextStyle(color: textSecondary),
                  ),
                  Text(
                    '• Relay Module 5V untuk aktivasi sakelar otomatis pompa air.',
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label, bool isDark) {
    final isSelected = _activeTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF084B83))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStyleCard({
    required String code,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    bool isToggle = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToggle ? accentColor : cardBorder,
            width: isToggle ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
