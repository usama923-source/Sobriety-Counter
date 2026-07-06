import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/theme_service.dart';

/// Provider for the ThemeService instance.
final themeServiceProvider = ChangeNotifierProvider<ThemeService>((ref) {
  return ThemeService();
});

/// Provider that exposes the current ThemeMode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeServiceProvider).themeMode;
});

/// Provider that exposes whether dark mode is active.
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeServiceProvider).isDarkMode;
});
