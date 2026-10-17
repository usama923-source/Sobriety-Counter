import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/services/theme_service.dart';

/// Provider for the ThemeService instance.
final themeServiceProvider = ChangeNotifierProvider<ThemeService>((ref) {
  final service = ThemeService();
  // Restore the saved theme as soon as the service is first needed.
  service.init();
  return service;
});

/// Provider that exposes the current ThemeMode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeServiceProvider).themeMode;
});

/// Provider that exposes whether the user has unlocked Pro.
///
/// While [kProEnabled] is `false` (the free first release) every feature is
/// free, so this always resolves to `true` and every Pro gate passes. The
/// stored `is_pro` preference is only consulted once billing is switched on.
final isProProvider = FutureProvider<bool>((ref) async {
  if (!kProEnabled) return true;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_pro') ?? false;
});
