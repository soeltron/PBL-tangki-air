import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const _themeKey = 'isDarkMode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _themeMode = preferences.getBool(_themeKey) == true
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (error) {
      debugPrint('Failed to load theme preference: $error');
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }

  Future<void> setDarkMode(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_themeKey, isDark);
    } catch (error) {
      debugPrint('Failed to save theme preference: $error');
    }
  }
}
