import 'package:flutter/material.dart';

/// Core color palette for the QuitDrink Ai app.
/// Designed to feel calming, premium, and motivational.
class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color navyBlue = Color(0xFF1E3A5F);
  static const Color navyBlueLight = Color(0xFF2C5282);
  static const Color navyBlueDark = Color(0xFF142A47);

  // ── Secondary ────────────────────────────────────────────────────────────
  static const Color skyBlue = Color(0xFF7FB3D5);
  static const Color skyBlueLight = Color(0xFFA8D0E6);
  static const Color skyBlueDark = Color(0xFF5A9BC4);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color softTeal = Color(0xFF7EC8C3);
  static const Color softTealLight = Color(0xFFA8DCD8);
  static const Color softTealDark = Color(0xFF5BB4AE);

  // ── Surface / Background ─────────────────────────────────────────────────
  static const Color mint = Color(0xFFE8F4F8);
  static const Color mintLight = Color(0xFFF0F8FA);
  static const Color lightGray = Color(0xFFF5F7FA);
  static const Color lightGrayAlt = Color(0xFFEDF0F5);
  static const Color white = Color(0xFFFFFFFF);

  // ── Dark Theme Surfaces ──────────────────────────────────────────────────
  static const Color darkSurface = Color(0xFF121B28);
  static const Color darkSurfaceAlt = Color(0xFF1A2537);
  static const Color darkCard = Color(0xFF1E2D42);
  static const Color darkCardAlt = Color(0xFF25364D);

  // ── Accent ───────────────────────────────────────────────────────────────
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenLight = Color(0xFF81C784);
  static const Color softOrange = Color(0xFFFFB74D);
  static const Color softOrangeLight = Color(0xFFFFD89B);
  static const Color softRed = Color(0xFFEF5350);
  static const Color softRedLight = Color(0xFFE57373);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFA500);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textOnDark = Color(0xFFF7FAFC);
  static const Color textOnDarkSecondary = Color(0xFFB0BEC5);

  // ── 60-30-10 Theme ───────────────────────────────────────────────────────
  // 30% Primary
  static const Color primaryLight = Color(0xFF14395C);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF9CC3E0);
  static const Color onPrimaryDark = Color(0xFF0B1E30);

  // 10% Accent (fills and icons only — never text, never under white text)
  static const Color accent = Color(0xFF70B0D0);

  // 60% Neutral backgrounds
  static const Color bgLight = Color(0xFFF4F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFE9EEF5);
  static const Color bgDark = Color(0xFF0F1B2B);
  static const Color surfaceDark = Color(0xFF16263A);
  static const Color surfaceAltDark = Color(0xFF1E3350);

  // Success text
  static const Color successTextLight = Color(0xFF2E7D32);
  static const Color successTextDark = Color(0xFF81C784);

  // Secondary text on light surfaces
  static const Color secondaryTextLight = Color(0xFF4A5568);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static Color shadowLight = Colors.black.withValues(alpha: 0.06);
  static Color shadowDark = Colors.black.withValues(alpha: 0.20);
  static Color shadowAccent = const Color(0xFF1E3A5F).withValues(alpha: 0.15);
}

/// Theme-aware color helpers for the 60-30-10 palette.
///
/// Use these instead of repeating `isDark ? ... : ...` for these roles.
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 30% — the single brand primary (deep navy in light, sky blue in dark).
  Color get primary =>
      isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;

  /// Text/icon color to place on top of [primary].
  Color get onPrimary =>
      isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;

  /// 10% — accent for fills and icons only (never text, never under white).
  Color get accent => AppColors.accent;

  /// Secondary body text color with adequate contrast in both modes.
  Color get secondaryText =>
      isDarkMode ? AppColors.textOnDarkSecondary : AppColors.secondaryTextLight;

  /// Success text color with adequate contrast in both modes.
  Color get successText =>
      isDarkMode ? AppColors.successTextDark : AppColors.successTextLight;
}
