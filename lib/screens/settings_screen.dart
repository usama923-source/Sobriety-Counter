import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/core/providers/quotes_provider.dart';
import 'package:quit_drinking/core/providers/reasons_provider.dart';
import 'package:quit_drinking/core/providers/savings_provider.dart';
import 'package:quit_drinking/core/providers/breathing_provider.dart';
import 'package:quit_drinking/core/providers/checkin_provider.dart';
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
  String _currency = 'USD';
  bool _isLoading = true;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'PKR'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('notifications_enabled') ?? false;
      final savedTime = prefs.getString('reminder_time');
      if (savedTime != null) {
        final parts = savedTime.split(':');
        if (parts.length == 2) {
          _reminderTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 20,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      _currency = prefs.getString('currency') ?? 'USD';
      _isLoading = false;
    });
  }

  Future<void> _setDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _dailyReminder = value);
  }

  Future<void> _setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_time', '${time.hour}:${time.minute}');
    setState(() => _reminderTime = time);
  }

  Future<void> _setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    setState(() => _currency = currency);
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
                'This will erase everything.\\nAre you sure?',
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
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                        side: BorderSide(
                          color:
                              isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMd,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMd,
                        ),
                      ),
                      child: const Text('Delete Everything'),
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Re-init all services so they pick up the cleared state
      if (mounted) {
        ref.read(sobrietyServiceProvider).init();
        ref.read(quotesServiceProvider).init();
        ref.read(reasonsServiceProvider).init();
        ref.read(savingsServiceProvider).init();
        ref.read(breathingServiceProvider).init();
        // CheckInService has an _initialized guard, so force it by clearing first
        ref.invalidate(checkinServiceProvider);
        ref.read(checkinServiceProvider);
        setState(() {
          _dailyReminder = false;
          _reminderTime = const TimeOfDay(hour: 20, minute: 0);
          _currency = 'USD';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All data has been reset.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
          ),
        );
      }
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
                        color: AppColors.softOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 22,
                        color: AppColors.softOrange,
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
                      activeThumbColor: AppColors.navyBlue,
                      activeTrackColor: AppColors.skyBlueLight.withValues(alpha: 0.5),
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
                            color: AppColors.skyBlue.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSm),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            size: 22,
                            color: AppColors.skyBlue,
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
                          onChanged: _setDailyReminder,
                          activeThumbColor: AppColors.navyBlue,
                          activeTrackColor:
                              AppColors.skyBlueLight.withValues(alpha: 0.5),
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
                        color: AppColors.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        size: 22,
                        color: AppColors.successGreen,
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
                      value: _currency,
                      dropdownColor:
                          isDark ? AppColors.darkSurfaceAlt : AppColors.white,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                      underline: const SizedBox(),
                      items: _currencies.map((c) {
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
                    TextButton(
                      onPressed: _resetAllData,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.softRed,
                        backgroundColor: AppColors.softRed.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
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
                      iconColor: AppColors.navyBlue,
                      label: 'Privacy Policy',
                      isDark: isDark,
                      onTap: () => _launchUrl('https://sobertoday.app/privacy'),
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.softOrange,
                      label: 'Rate the App',
                      isDark: isDark,
                      onTap: () => _launchUrl(
                        'https://play.google.com/store/apps/details?id=com.example.quit_drinking',
                      ),
                    ),
                    _AboutDivider(isDark: isDark),
                    _AboutTile(
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.softTeal,
                      label: 'Contact Us',
                      isDark: isDark,
                      onTap: () => _launchUrl(
                        'mailto:support@sobertoday.app?subject=Sober%20Today%20Feedback',
                      ),
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
        onPressed: () => Navigator.of(context).pop(),
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
