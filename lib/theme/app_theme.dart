import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// Builds the complete light and dark theme for QuitDrink Ai.
class AppTheme {
  AppTheme._();

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.navyBlue,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.mint,
      onPrimaryContainer: AppColors.navyBlueDark,
      secondary: AppColors.skyBlue,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.skyBlueLight,
      onSecondaryContainer: AppColors.navyBlueDark,
      tertiary: AppColors.softTeal,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.mint,
      onTertiaryContainer: AppColors.navyBlueDark,
      error: AppColors.softRed,
      onError: AppColors.white,
      errorContainer: AppColors.softRedLight.withValues(alpha: 0.2),
      onErrorContainer: AppColors.softRed,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textTertiary,
      outlineVariant: AppColors.lightGrayAlt,
      surfaceTint: AppColors.navyBlue,
      shadow: AppColors.shadowLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,

      // ── Text Theme ──────────────────────────────────────────────────────
      textTheme: GoogleFonts.latoTextTheme().copyWith(
        displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingXs,
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.navyBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.lightGrayAlt,
          disabledForegroundColor: AppColors.textTertiary,
          shadowColor: AppColors.shadowAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.navyBlue,
          side: const BorderSide(color: AppColors.navyBlue, width: 1.5),
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navyBlue,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
        ),
      ),

      // ── Floating Action Button ──────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppColors.navyBlue,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.navyBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.softRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.softRed, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
      ),

      // ── Snackbar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),

      // ── Bottom Navigation ───────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.navyBlue,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Navigation Rail ─────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.mint,
        labelType: NavigationRailLabelType.all,
      ),

      // ── Drawer ──────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGrayAlt,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mint,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.navyBlueDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXs,
          vertical: AppConstants.spacingXxs,
        ),
      ),

      // ── Scaffold ────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.lightGray,

      // ── Bottom Sheet ────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.radiusLg),
            topRight: Radius.circular(AppConstants.radiusLg),
          ),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),      // ── Progress Indicator ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navyBlue,
        linearTrackColor: AppColors.mint,
        circularTrackColor: AppColors.mint,
      ),

      // ── Tooltip ─────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navyBlueDark,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.skyBlueLight,
      onPrimary: AppColors.navyBlueDark,
      primaryContainer: AppColors.navyBlue,
      onPrimaryContainer: AppColors.mint,
      secondary: AppColors.skyBlue,
      onSecondary: AppColors.navyBlueDark,
      secondaryContainer: AppColors.navyBlue,
      onSecondaryContainer: AppColors.skyBlueLight,
      tertiary: AppColors.softTeal,
      onTertiary: AppColors.navyBlueDark,
      tertiaryContainer: AppColors.navyBlue,
      onTertiaryContainer: AppColors.mint,
      error: AppColors.softRedLight,
      onError: AppColors.navyBlueDark,
      errorContainer: AppColors.softRed.withValues(alpha: 0.2),
      onErrorContainer: AppColors.softRedLight,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textOnDark,
      onSurfaceVariant: AppColors.textOnDarkSecondary,
      outline: AppColors.textOnDarkSecondary.withValues(alpha: 0.5),
      outlineVariant: AppColors.darkCardAlt,
      surfaceTint: AppColors.skyBlue,
      shadow: AppColors.shadowDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,

      // ── Text Theme ──────────────────────────────────────────────────────
      textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textOnDark,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDark,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        surfaceTintColor: AppColors.darkCard,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingXs,
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.skyBlueLight,
          foregroundColor: AppColors.navyBlueDark,
          disabledBackgroundColor: AppColors.darkCardAlt,
          disabledForegroundColor: AppColors.textOnDarkSecondary.withValues(alpha: 0.5),
          shadowColor: AppColors.shadowDark,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.skyBlueLight,
          side: const BorderSide(color: AppColors.skyBlueLight, width: 1.5),
          disabledForegroundColor: AppColors.textOnDarkSecondary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.skyBlueLight,
          disabledForegroundColor: AppColors.textOnDarkSecondary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Floating Action Button ──────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppColors.skyBlueLight,
        foregroundColor: AppColors.navyBlueDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.skyBlueLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.softRedLight, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.softRedLight, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textOnDarkSecondary,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textOnDarkSecondary.withValues(alpha: 0.6),
        ),
      ),

      // ── Snackbar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),

      // ── Bottom Navigation ───────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.skyBlueLight,
        unselectedItemColor: AppColors.textOnDarkSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Navigation Rail ─────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.navyBlue,
        labelType: NavigationRailLabelType.all,
      ),

      // ── Drawer ──────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.darkCardAlt,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navyBlue,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.skyBlueLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXs,
          vertical: AppConstants.spacingXxs,
        ),
      ),

      // ── Scaffold ────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.darkSurface,

      // ── Bottom Sheet ────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.radiusLg),
            topRight: Radius.circular(AppConstants.radiusLg),
          ),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),

      // ── Progress Indicator ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.skyBlueLight,
        linearTrackColor: AppColors.darkCardAlt,
        circularTrackColor: AppColors.darkCardAlt,
      ),

      // ── Tooltip ─────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkCardAlt,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textOnDark,
        ),
      ),
    );
  }
}
