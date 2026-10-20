/// Master switch for Pro gating and billing.
///
/// The first release ships every feature free, so this stays `false`: all Pro
/// gates pass, no paywall UI is shown, and the billing code (the upgrade sheet
/// and the `is_pro` preference) stays in the project but unreachable. Set it to
/// `true` to switch billing back on.
const bool kProEnabled = false;

/// Shows the "Details" action on AI error SnackBars and the raw exception
/// dialog behind it. Debug-only affordance: set to `false` for a production
/// release so users never see provider error text.
const bool kShowErrorDetails = true;

/// App-wide constants used throughout QuitDrink.
class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'QuitDrink';

  /// Brand tagline — the single source of truth for the app's tagline text.
  static const String tagline = 'Find your calm, anytime.';

  // ── Layout ───────────────────────────────────────────────────────────────
  static const double maxContentWidth = 1200.0;
  static const double maxNarrowWidth = 600.0;

  // ── Spacing ──────────────────────────────────────────────────────────────
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double spacingXxxl = 64.0;

  // ── Border Radius ────────────────────────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Animation ────────────────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMed = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // ── Sizing ───────────────────────────────────────────────────────────────
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double avatarSize = 56.0;
}
