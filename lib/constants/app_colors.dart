import 'package:flutter/material.dart';

/// Core color palette for the Sober Today app.
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
  static const Color mint = Color(0xFFD7F5EF);
  static const Color mintLight = Color(0xFFE8FAF6);
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

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textOnDark = Color(0xFFF7FAFC);
  static const Color textOnDarkSecondary = Color(0xFFB0BEC5);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static Color shadowLight = Colors.black.withValues(alpha: 0.06);
  static Color shadowDark = Colors.black.withValues(alpha: 0.20);
  static Color shadowAccent = const Color(0xFF1E3A5F).withValues(alpha: 0.15);
}
