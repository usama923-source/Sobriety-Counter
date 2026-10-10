import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/services/checkin_service.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section 10 — Daily Check-In Card.
///
/// Records whether the user stayed alcohol-free or drank today (once per day).
/// Tapping "I Drank Today" asks for confirmation and resets the sobriety
/// journey. Displays current/longest streak, success percentage, weekly
/// summary, and a monthly calendar with color-coded days.
class DailyCheckinCard extends ConsumerWidget {
  final CheckInService service;

  const DailyCheckinCard({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 22,
                  color: context.primary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Daily Check-In',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _todayDate(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.secondaryTextLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Question text
          Text(
            'Did you stay alcohol-free today?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Check-in buttons
          Row(
            children: [
              Expanded(
                child: _CheckInButton(
                  emoji: '\u{1F60A}',
                  label: 'Stayed\nAlcohol-Free',
                  color: AppColors.successGreen,
                  isDark: isDark,
                  isSelected: service.todayCheckedIn && service.todaySuccessful,
                  enabled: !service.todayCheckedIn,
                  onTap: () => service.checkIn(true),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _CheckInButton(
                  emoji: '\u{1F614}',
                  label: 'I Drank\nToday',
                  color: AppColors.softRed,
                  isDark: isDark,
                  isSelected: service.todayCheckedIn && !service.todaySuccessful,
                  enabled: !service.todayCheckedIn,
                  onTap: () => _showDrankDialog(context, ref),
                ),
              ),
            ],
          ),

          // Already checked in message
          if (service.todayCheckedIn)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingSm),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      service.todaySuccessful
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      size: 16,
                      color: service.todaySuccessful
                          ? context.successText
                          : context.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service.todaySuccessful
                          ? 'Checked in! Great job staying sober today.'
                          : 'Checked in. Tomorrow is a new day!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: service.todaySuccessful
                            ? context.successText
                            : context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppConstants.spacingLg),

          // Stats row — even spacing, each stat flexes so narrow screens
          // shrink rather than overflow.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                value: '${service.successPercentage}%',
                label: 'Success',
                icon: Icons.trending_up_rounded,
                color: context.successText,
                isDark: isDark,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              _MiniStat(
                value: '${service.currentStreak}',
                label: 'Current Streak',
                icon: Icons.local_fire_department_rounded,
                color: context.primary,
                isDark: isDark,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              _MiniStat(
                value: '${service.longestStreak}',
                label: 'Longest Streak',
                icon: Icons.emoji_events_rounded,
                color: context.accent,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Weekly Summary
          _buildWeeklySummary(isDark),

          const SizedBox(height: AppConstants.spacingLg),

          // Monthly Calendar
          _buildMonthlyCalendar(isDark),
        ],
      ),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  // ── Drank Dialog ───────────────────────────────────────────────────

  /// Compassionate confirmation before resetting the sobriety journey.
  /// On confirm, resets [SobrietyService]'s start date to now and refreshes
  /// the provider so the counter resets immediately on the home screen.
  Future<void> _showDrankDialog(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppConstants.spacingSm),
            // Compassionate red heart icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softRed.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 32,
                color: AppColors.softRed,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              "It's Okay, Don't Give Up",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Every setback is a setup for a comeback. '
              'Your journey starts again right now. '
              'You are stronger than you think! 💪',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.secondaryTextLight,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? AppColors.textOnDarkSecondary : AppColors.secondaryTextLight,
                      side: BorderSide(
                        color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Reset My Journey'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'sobriety_start_date',
        DateTime.now().toIso8601String(),
      );
      // Refresh sobriety service so the counter resets immediately
      await ref.read(sobrietyServiceProvider).init();
    }
  }

  Widget _buildWeeklySummary(bool isDark) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon ... 7=Sun
    final days = <Widget>[];
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final status = service.getStatus(key);
      final isToday = i == 0;

      days.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day label
              Text(
                dayLabels[(7 - i + weekday - 1) % 7],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.secondaryTextLight,
                ),
              ),
              const SizedBox(height: 4),
              // Status indicator
              AnimatedContainer(
                duration: AppConstants.animationFast,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == null
                      ? (isDark
                          ? AppColors.darkCardAlt
                          : AppColors.lightGrayAlt)
                      : status
                          ? AppColors.successGreen
                          : AppColors.softRed,
                  border: isToday
                      ? Border.all(
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: status == null
                          ? (isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.secondaryTextLight)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Row(children: days),
        const SizedBox(height: AppConstants.spacingXxs),
        // Legend
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.successGreen, 'Sober', isDark),
              const SizedBox(width: AppConstants.spacingMd),
              _legendDot(AppColors.softRed, 'Drank', isDark),
              const SizedBox(width: AppConstants.spacingMd),
              _legendDot(
                isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                'No check-in',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCalendar(bool isDark) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun
    final monthData = service.getAllForMonth(year, month);

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final dayWidgets = <Widget>[];

    // Empty cells for days before the 1st
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const Expanded(child: SizedBox(height: 32)));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final key = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final status = monthData[key];
      final isToday = day == now.day;

      dayWidgets.add(
        Expanded(
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == null
                  ? (isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt)
                  : status
                      ? AppColors.successGreen
                      : AppColors.softRed,
              border: isToday
                  ? Border.all(
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                      width: 2.5,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: status == null
                      ? (isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.secondaryTextLight)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Fill remaining cells
    final remaining = 7 - ((dayWidgets.length) % 7);
    if (remaining < 7) {
      for (int i = 0; i < remaining; i++) {
        dayWidgets.add(const Expanded(child: SizedBox(height: 32)));
      }
    }

    // Build rows of 7
    final rows = <Widget>[];
    const dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    rows.add(
      Row(
        children: dayHeaders
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.secondaryTextLight,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
    rows.add(const SizedBox(height: 4));

    for (int i = 0; i < dayWidgets.length; i += 7) {
      final end = (i + 7 > dayWidgets.length) ? dayWidgets.length : i + 7;
      rows.add(
        Row(
          children: dayWidgets.sublist(i, end),
        ),
      );
    }

    // Counts for the month
    final monthSuccessCount = monthData.values.where((v) => v).length;
    final monthDrankCount = monthData.values.where((v) => !v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthNames[month - 1],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            Text(
              '$monthSuccessCount sober, $monthDrankCount drank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.secondaryTextLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        ...rows,
      ],
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.secondaryTextLight,
          ),
        ),
      ],
    );
  }
}

// ── Check-In Button ─────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isDark;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _CheckInButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingLg,
            horizontal: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : (enabled
                    ? color.withValues(alpha: isDark ? 0.08 : 0.05)
                    : (isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt)),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isSelected
                  ? color
                  : (enabled
                      ? color.withValues(alpha: 0.3)
                      : (isDark
                          ? AppColors.darkCardAlt
                          : AppColors.lightGrayAlt)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isSelected
                      ? color
                      : (enabled
                          ? (isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary)
                          : (isDark
                              ? AppColors.textOnDarkSecondary
                                  .withValues(alpha: 0.4)
                              : AppColors.secondaryTextLight)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Stat Widget ────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingSm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.secondaryTextLight,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
