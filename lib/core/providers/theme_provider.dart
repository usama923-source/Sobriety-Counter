import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/services/theme_service.dart';

/// Provider for the ThemeService instance.
final themeServiceProvider = ChangeNotifierProvider<ThemeService>((ref) {
  return ThemeService();
});

/// Provider that exposes the current ThemeMode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeServiceProvider).themeMode;
});

/// Provider that exposes whether the user has unlocked Pro.
final isProProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_pro') ?? false;
});
