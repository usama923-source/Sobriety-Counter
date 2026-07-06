import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quit_drinking/constants/app_colors.dart';

/// Centralized text styles for the Sober Today app.
/// Uses Google Fonts for a modern, clean, minimal look.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ──────────────────────────────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w300,
    height: 1.12,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w300,
    height: 1.15,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ── Headline ─────────────────────────────────────────────────────────────
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ── Title ────────────────────────────────────────────────────────────────
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // ── Body ─────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // ── Label ────────────────────────────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ── Special ──────────────────────────────────────────────────────────────
  static TextStyle counter = GoogleFonts.inter(
    fontSize: 72,
    fontWeight: FontWeight.w200,
    height: 1.0,
    letterSpacing: -2.0,
    color: AppColors.navyBlue,
  );

  static TextStyle counterUnit = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  static TextStyle quote = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    height: 1.60,
    letterSpacing: 0.2,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
  );
}

/// Extension to easily apply dark theme text colors.
extension DarkTextStyles on TextStyle {
  TextStyle get onDark => copyWith(
        color: AppColors.textOnDark,
      );

  TextStyle get onDarkSecondary => copyWith(
        color: AppColors.textOnDarkSecondary,
      );
}
