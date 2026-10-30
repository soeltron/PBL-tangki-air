import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/mqtt_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService().load();
  await MqttService().loadTankSettings();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authService = AuthService();
  final themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    authService.addListener(_onStateChange);
    themeService.addListener(_onStateChange);
  }

  @override
  void dispose() {
    authService.removeListener(_onStateChange);
    themeService.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Tandon IoT',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,

      // LIGHT THEME (White & Ocean Blue)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
          primary: const Color(0xFF0284C7),
          secondary: const Color(0xFF0369A1),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // DARK THEME (Cyberpunk Deep Navy & Cyan)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF131C2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090D16),
          elevation: 0,
        ),
      ),

      home: authService.isLoggedIn ? const HomeShell() : const LoginPage(),
    );
  }
}
