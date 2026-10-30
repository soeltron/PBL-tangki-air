import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/mqtt_service.dart';
import '../services/theme_service.dart';
import 'dashboard_page.dart';
import 'control_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final authService = AuthService();
  final mqttService = MqttService();
  final themeService = ThemeService();

  final List<Widget> _pages = const [
    DashboardPage(),
    ControlPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  final List<String> _titles = const [
    'Beranda',
    'Kontrol Pompa',
    'Riwayat Telemetri',
    'Pengaturan Sistem',
  ];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = authService.username.isNotEmpty
        ? authService.username
        : 'kelompok2';
    final isDark = themeService.isDarkMode;

    final bgColor = isDark ? const Color(0xFF090D16) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF090D16)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
            Text(
              _titles[_selectedIndex],
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Theme Toggle Button (Dark 🌙 / Light ☀️)
          IconButton(
            tooltip: isDark ? 'Ganti ke Mode Terang' : 'Ganti ke Mode Gelap',
            onPressed: () async {
              await themeService.toggleTheme();
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131C2E)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF24324A)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amber : const Color(0xFF0284C7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Right Profile Avatar Icon
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
                child: Center(
                  child: Text(
                    username[0].toUpperCase(),
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // SIDEBAR (Drawer) Navigation
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0D1424) : Colors.white,
        child: Column(
          children: [
            // Drawer Profile Header Banner
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
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
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Role: Pengguna',
                            style: TextStyle(
                              color: Color(0xFFBAE6FD),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mode Gelap / Terang Switch Item in Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131C2E)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF24324A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDark
                              ? Colors.amber
                              : const Color(0xFF0284C7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isDark ? 'Tema Gelap' : 'Tema Terang',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: const Color(0xFF00E5FF),
                      activeTrackColor: const Color(0xFF00E5FF)
                          .withValues(alpha: 0.3),
                      inactiveThumbColor: const Color(0xFF0284C7),
                      inactiveTrackColor: const Color(0xFF0284C7)
                          .withValues(alpha: 0.2),
                      onChanged: (val) async {
                        await themeService.setDarkMode(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NAVIGASI UTAMA',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Sidebar Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Beranda / Dashboard',
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.power_settings_new_rounded,
                    label: 'Kontrol Pompa Air',
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.show_chart_rounded,
                    label: 'Riwayat Telemetri',
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan System',
                  ),
                ],
              ),
            ),

            // Bottom Logout Option
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Konfirmasi Logout'),
                      content: const Text('Apakah anda yakin akan logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (shouldLogout == true && context.mounted) {
                    Navigator.pop(context);
                    await authService.logout();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Keluar SIKAD / App',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Active Page Body
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // BOTTOM NAVBAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                _buildNavItem(1, Icons.power_settings_new_rounded, 'Kontrol'),
                _buildNavItem(2, Icons.show_chart_rounded, 'Riwayat'),
                _buildNavItem(3, Icons.settings_rounded, 'Pengaturan'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final isDark = themeService.isDarkMode;
    final accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF0284C7);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: accentColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? accentColor
                  : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF64748B)),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white : const Color(0xFF334155)),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final isDark = themeService.isDarkMode;
    final accentColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF0284C7);

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: accentColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : const Color(0xFF64748B),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
