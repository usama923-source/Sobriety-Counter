import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:quit_drinking/widgets/milestone_badges.dart';

/// Section 2 — Sobriety Counter Card.
///
/// Displays a live days / hours / minutes / seconds counter that updates
/// every second. Shows the start date, current streak, next milestone,
/// and milestone badges. If no quit date has been set, prompts the user
/// to choose one.
class SobrietyCounterCard extends StatelessWidget {
  final SobrietyService service;

  const SobrietyCounterCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!service.hasQuitDate) {
      return _buildNoDateCard(context, isDark);
    }

    return SoberCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      gradient: isDark
          ? LinearGradient(
              colors: [
                AppColors.darkCard,
                AppColors.darkCardAlt.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : LinearGradient(
              colors: [
                AppColors.white,
                AppColors.mint.withValues(alpha: 0.25),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────────────
          Center(
            child: Text(
              'Your Sobriety Journey',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Live Counter Row ───────────────────────────────────────
          _LiveCounterRow(
            totalDays: service.totalDays,
            hours: service.hours,
            minutes: service.minutes,
            seconds: service.seconds,
            isDark: isDark,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Info Rows ──────────────────────────────────────────────
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Started on',
            value: service.startDateFormatted,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _InfoRow(
            icon: Icons.trending_up_rounded,
            label: 'Current streak',
            value: '${service.totalDays} day${service.totalDays == 1 ? '' : 's'}',
            valueColor: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _InfoRow(
            icon: Icons.flag_rounded,
            label: 'Next milestone',
            value: _nextMilestoneText(service),
            valueColor: AppColors.successGreen,
            isDark: isDark,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Milestone Badges ───────────────────────────────────────
          MilestoneBadges(milestones: service.milestonesWithStatus),

          const SizedBox(height: AppConstants.spacingLg),

          // ── I Drank Button ────────────────────────────────────────
          Center(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showResetDialog(context, service),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.7)
                      : AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                label: Text(
                  'I Drank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textOnDarkSecondary.withValues(alpha: 0.7)
                        : AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkCardAlt
                        : AppColors.lightGrayAlt,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reset Dialog ───────────────────────────────────────────────────

  Future<void> _showResetDialog(BuildContext context, SobrietyService service) async {
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
            // Compassionate icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softOrange.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 32,
                color: AppColors.softOrange,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              'It\'s okay, every day is a new chance.\nYour journey continues now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Your sobriety timer will reset to zero.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await service.resetSobriety();
    }
  }

  // ── No-Date State ──────────────────────────────────────────────────

  Widget _buildNoDateCard(BuildContext context, bool isDark) {
    return SoberCard(
      child: Column(
        children: [
          const SizedBox(height: AppConstants.spacingMd),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.skyBlue.withValues(alpha: 0.15)
                  : AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 28,
              color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'Begin Your Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Set your quit date to start tracking\nyour sobriety journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
              label: const Text('Set Quit Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                foregroundColor: isDark ? AppColors.navyBlueDark : AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],
      ),
    );
  }

  // ── Date Picker ────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 365 * 20)),
      lastDate: now,
      helpText: 'Select your quit date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              headerBackgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCardAlt
                  : AppColors.navyBlue,
              headerForegroundColor: AppColors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.white;
                }
                return Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textOnDark
                    : AppColors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).brightness == Brightness.dark
                      ? AppColors.skyBlueLight
                      : AppColors.navyBlue;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await service.setQuitDate(picked);
    }
  }

  String _nextMilestoneText(SobrietyService svc) {
    final next = svc.nextMilestone;
    if (next == null) return 'All milestones completed! 🎉';
    final daysLeft = svc.daysUntilNextMilestone!;
    return '${next.label} — $daysLeft day${daysLeft == 1 ? '' : 's'} to go';
  }
}

// ── Live Counter Row ────────────────────────────────────────────────────

class _LiveCounterRow extends StatelessWidget {
  final int totalDays;
  final int hours;
  final int minutes;
  final int seconds;
  final bool isDark;

  const _LiveCounterRow({
    required this.totalDays,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TimeTile(value: totalDays, label: 'Days', isDark: isDark, padDigits: false)),
        _buildSeparator(isDark),
        Expanded(child: _TimeTile(value: hours, label: 'Hours', isDark: isDark)),
        _buildSeparator(isDark),
        Expanded(child: _TimeTile(value: minutes, label: 'Min', isDark: isDark)),
        _buildSeparator(isDark),
        Expanded(child: _TimeTile(value: seconds, label: 'Sec', isDark: isDark)),
      ],
    );
  }

  Widget _buildSeparator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: isDark
              ? AppColors.textOnDarkSecondary.withValues(alpha: 0.4)
              : AppColors.textTertiary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ── Single Time Tile ────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final int value;
  final String label;
  final bool isDark;
  final bool padDigits;

  const _TimeTile({
    required this.value,
    required this.label,
    required this.isDark,
    this.padDigits = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = padDigits ? value.toString().padLeft(2, '0') : value.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: AppConstants.animationFast,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayValue,
              key: ValueKey('$value-$label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                height: 1.1,
                color: isDark ? AppColors.textOnDark : AppColors.navyBlue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ── Info Row ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? AppColors.textOnDarkSecondary.withValues(alpha: 0.6)
              : AppColors.textTertiary,
        ),
        const SizedBox(width: AppConstants.spacingXs),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ??
                  (isDark ? AppColors.textOnDark : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
