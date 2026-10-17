import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/constants/currencies.dart';
import 'package:quit_drinking/core/providers/breathing_provider.dart';
import 'package:quit_drinking/core/providers/checkin_provider.dart';
import 'package:quit_drinking/core/providers/currency_provider.dart';
import 'package:quit_drinking/core/providers/journal_provider.dart';
import 'package:quit_drinking/core/providers/quotes_provider.dart';
import 'package:quit_drinking/core/providers/reasons_provider.dart';
import 'package:quit_drinking/core/providers/savings_provider.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/core/providers/weight_tracker_provider.dart';
import 'package:quit_drinking/core/services/notification_service.dart';
import 'package:quit_drinking/screens/onboarding/onboarding_screen.dart';
import 'package:quit_drinking/screens/privacy_policy_screen.dart';
import 'package:quit_drinking/screens/terms_of_service_screen.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings screen with Appearance, Notifications, Preferences, Data, and About sections.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // The currency lives in its own service — wait for it to read storage so
    // the dropdown never shows the default while the real value is loading.
    await ref.read(currencyServiceProvider).ensureInitialized();

    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyReminder = prefs.getBool('reminder_enabled') ?? false;
      var reminderTime = const TimeOfDay(hour: 20, minute: 0);
      final savedTime = prefs.getString('reminder_time');
      if (savedTime != null) {
        final parts = savedTime.split(':');
        if (parts.length == 2) {
          reminderTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 20,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _dailyReminder = dailyReminder;
        _reminderTime = reminderTime;
        _isLoading = false;
      });
    } catch (_) {
      // Any prefs read failure (e.g. corrupted storage) falls back to safe defaults.
      if (!mounted) return;
      setState(() {
        _dailyReminder = false;
        _reminderTime = const TimeOfDay(hour: 20, minute: 0);
        _isLoading = false;
      });
    }
  }

  /// Enable/disable the daily reminder. On enable, asks the user to pick a
  /// time and schedules the repeating notification; on disable, cancels it.
  Future<void> _setDailyReminder(bool value) async {
    if (!value) {
      await NotificationService().cancelReminder();
      if (mounted) setState(() => _dailyReminder = false);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
              hourMinuteColor:
                  isDark ? AppColors.darkCardAlt : AppColors.lightGray,
              hourMinuteTextColor:
                  isDark ? AppColors.textOnDark : AppColors.textPrimary,
              dayPeriodColor:
                  isDark ? AppColors.darkCardAlt : AppColors.lightGray,
              dayPeriodTextColor:
                  isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      // User cancelled the picker — leave the reminder off.
      if (mounted) setState(() => _dailyReminder = false);
      return;
    }

    await NotificationService().scheduleDailyReminder(picked);
    if (mounted) {
      setState(() {
        _dailyReminder = true;
        _reminderTime = picked;
      });
    }
  }

  /// Re-pick the reminder time (only visible when the reminder is enabled).
  Future<void> _setReminderTime(TimeOfDay time) async {
    await NotificationService().scheduleDailyReminder(time);
    if (mounted) setState(() => _reminderTime = time);
  }

  /// Persists the choice and notifies the shared currency state, which the
  /// Money Saved card (and any other money UI) follows.
  Future<void> _setCurrency(String currency) async {
    await ref.read(currencyServiceProvider).setCurrency(currency);
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.softRed.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 32,
                  color: AppColors.softRed,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text(
                'Reset All Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'This will erase all your data including sobriety date, '
                'reasons, and chat history. Are you sure?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color:
                      isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMd,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMd,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'Delete Everything',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      // Cancel any scheduled notification before wiping prefs
      await NotificationService().cancelReminder();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // Dropping the stored data is not enough: every service keeps a copy in
      // memory, and those copies would be shown again on the next launch.
      // Invalidate them all so each reloads from the now-empty store.
      ref.invalidate(sobrietyServiceProvider);
      ref.invalidate(checkinServiceProvider);
      ref.invalidate(savingsServiceProvider);
      ref.invalidate(quotesServiceProvider);
      ref.invalidate(breathingServiceProvider);
      ref.invalidate(reasonsServiceProvider);
      ref.invalidate(journalProvider);
      ref.invalidate(weightTrackerProvider);
      ref.invalidate(currencyServiceProvider);
      ref.invalidate(themeServiceProvider);
      ref.invalidate(isProProvider);

      // Navigate to onboarding, removing all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
        appBar: _buildAppBar(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: _buildAppBar(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Appearance ────────────────────────────────────────────
              _SectionHeader(title: 'Appearance', isDark: isDark),
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                  vertical: AppConstants.spacingMd,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandLightBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 22,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppColors.textOnDark : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (_) =>
                          ref.read(themeServiceProvider).toggleTheme(),
                      activeThumbColor: AppColors.brandPrimary,
                      activeTrackColor: AppColors.brandLightBlue.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Notifications ─────────────────────────────────────────
              _SectionHeader(title: 'Notifications', isDark: isDark),
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                  vertical: AppConstants.spacingMd,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSm),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            size: 22,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            'Daily Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch(
                          value: _dailyReminder,
                          onChanged: (value) => _setDailyReminder(value),
                          activeThumbColor: AppColors.brandPrimary,
                          activeTrackColor:
                              AppColors.brandLightBlue.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    if (_dailyReminder) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      const Divider(height: 1),
                      const SizedBox(height: AppConstants.spacingMd),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  timePickerTheme: TimePickerThemeData(
                                    backgroundColor: isDark
                                        ? AppColors.darkSurfaceAlt
                                        : AppColors.white,
                                    hourMinuteColor: isDark
                                        ? AppColors.darkCardAlt
                                        : AppColors.lightGray,
                                    hourMinuteTextColor: isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                    dayPeriodColor: isDark
                                        ? AppColors.darkCardAlt
                                        : AppColors.lightGray,
                                    dayPeriodTextColor: isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            await _setReminderTime(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: AppConstants.spacingXs),
                            Text(
                              'Reminder time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _reminderTime.format(context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingXs),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                      .withValues(alpha: 0.5)
                                  : AppColors.textTertiary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Preferences ───────────────────────────────────────────
              _SectionHeader(title: 'Preferences', isDark: isDark),
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                  vertical: AppConstants.spacingMd,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.brandLightBlue
                                : AppColors.brandPrimary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Icon(
                        Icons.monetization_on_rounded,
                        size: 22,
                        color: isDark
                            ? AppColors.brandLightBlue
                            : AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'Currency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppColors.textOnDark : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: ref.watch(currencyServiceProvider).code,
                      dropdownColor:
                          isDark ? AppColors.darkSurfaceAlt : AppColors.white,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                      underline: const SizedBox(),
                      items: Currencies.supported.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) _setCurrency(value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Data ──────────────────────────────────────────────────
              _SectionHeader(title: 'Data', isDark: isDark),
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                  vertical: AppConstants.spacingMd,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.softRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        size: 22,
                        color: AppColors.softRed,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset All Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Erase all sobriety data, reasons, and settings',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      child: TextButton(
                        onPressed: _resetAllData,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.softRed,
                          backgroundColor: AppColors.softRed.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingMd,
                            vertical: AppConstants.spacingSm,
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── About ─────────────────────────────────────────────────
              _SectionHeader(title: 'About', isDark: isDark),
              SoberCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AboutTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: AppColors.brandPrimary,
                      label: 'Privacy Policy',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.gavel_rounded,
                      iconColor: AppColors.softRed,
                      label: 'Terms of Service',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      ),
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.brandPrimary,
                      label: 'Rate the App',
                      isDark: isDark,
                      onTap: () => _launchUrl(
                        'https://play.google.com/store/apps/details?id=com.quitdrink.ai',
                      ),
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.brandPrimary,
                      label: 'Contact Us',
                      isDark: isDark,
                      onTap: () => _launchUrl(
                        'mailto:support.quitdrinkai@gmail.com?subject=QuitDrink%20Ai%20Feedback',
                      ),
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.health_and_safety_rounded,
                      iconColor: AppColors.softRed,
                      label: 'Get Help',
                      isDark: isDark,
                      onTap: _showGetHelpDialog,
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.info_outline_rounded,
                      iconColor:
                          isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
                      label: 'Version',
                      trailing: '1.0.0',
                      isDark: isDark,
                      onTap: null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Settings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Show crisis and alcohol-support resources.
  Future<void> _showGetHelpDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          'Get Help',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpLine(
              isDark,
              'If you are in immediate danger, call your local emergency '
              'number (for example 911 in the US or 999 in the UK).',
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _helpLine(
              isDark,
              'US: Call or text 988 — Suicide & Crisis Lifeline (24/7).',
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _helpLine(
              isDark,
              'US: SAMHSA National Helpline 1-800-662-4357 — free, '
              'confidential, 24/7 treatment referral.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _helpLine(bool isDark, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.brandLightBlue : AppColors.brandPrimary,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingLg,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark
                  ? AppColors.textOnDarkSecondary.withValues(alpha: 0.6)
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── About Tile ─────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final String? trailing;

  const _AboutTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                      : AppColors.textTertiary.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── About Divider ──────────────────────────────────────────────────────

class _AboutDivider extends StatelessWidget {
  final bool isDark;

  const _AboutDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
      ),
    );
  }
}
