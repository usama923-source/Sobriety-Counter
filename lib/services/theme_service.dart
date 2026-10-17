import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's theme mode (light / dark / system).
///
/// The selection is persisted under [storageKey] and loaded once at startup,
/// so dark mode survives a restart.
class ThemeService extends ChangeNotifier {
  /// Standard storage key for the persisted [ThemeMode].
  static const String storageKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  Future<void>? _initialLoad;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Loads the stored theme once. Safe to call repeatedly.
  Future<void> init() => _initialLoad ??= _load();

  Future<void> _load() async {
    var stored = ThemeMode.system;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Read the raw value: an oddly typed value simply falls back to the
      // system theme instead of failing the app.
      stored = _decode(prefs.get(storageKey));
    } catch (e) {
      debugPrint('[Theme] Failed to load the saved theme: $e');
    }

    if (stored != _themeMode) {
      _themeMode = stored;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, _encode(mode));
    } catch (e) {
      debugPrint('[Theme] Failed to save the theme: $e');
    }
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);

  static ThemeMode _decode(Object? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
