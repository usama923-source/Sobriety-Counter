import 'package:flutter/material.dart';

/// Manages the app's theme mode (light / dark / system).
class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);
}
