import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/services/breathing_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Section 6 — Breath Challenge Card.
///
/// A timer-based breath holding challenge with start/stop/reset, best time
/// tracking, and session history. All persisted via [BreathingService].
class BreathChallengeCard extends StatelessWidget {
  final BreathingService service;

  const BreathChallengeCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.softTeal.withValues(alpha: 0.2)
                      : AppColors.softTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.air_rounded,
                  size: 22,
                  color: AppColors.softTeal,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Breath Challenge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              if (service.hasBestTime)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.softTeal.withValues(alpha: 0.15)
                        : AppColors.softTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.softTeal),
                      const SizedBox(width: 4),
                      Text(
                        'Best: ${service.bestTimeDisplay}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.softTeal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // ── Disclaimer ──────────────────────────────────────────────
          const SizedBox(height: AppConstants.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical: AppConstants.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppColors.softOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: AppColors.softOrange.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.softOrange,
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Expanded(
                  child: Text(
                    'This is not a medical test. It is only a personal breathing challenge.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: AppColors.softOrange.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Timer Display ───────────────────────────────────────────
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: AppConstants.animationMed,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    service.elapsedDisplay,
                    key: ValueKey('timer_${service.elapsedSeconds}'),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1.0,
                      letterSpacing: -1.0,
                      color: isDark ? AppColors.textOnDark : AppColors.navyBlue,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXxs),
                Text(
                  service.isRunning ? 'Hold your breath...' : 'Press Start to begin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Control Buttons ─────────────────────────────────────────
          Row(
            children: [
              // Reset
              Expanded(
                child: _ControlButton(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset',
                  onTap: service.isRunning ? null : () => service.reset(),
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Start / Stop
              Expanded(
                flex: 2,
                child: _ControlButton(
                  icon: service.isRunning
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  label: service.isRunning ? 'Stop' : 'Start',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (service.isRunning) {
                      service.stop();
                    } else {
                      service.start();
                    }
                  },
                  color: service.isRunning
                      ? AppColors.softRed
                      : AppColors.successGreen,
                  isDark: isDark,
                  filled: true,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // (spacer for symmetry)
              const Expanded(child: SizedBox.shrink()),
            ],
          ),

          // ── History ─────────────────────────────────────────────────
          if (service.history.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => service.clearHistory(),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: service.history.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spacingXs),
                itemBuilder: (context, index) {
                  final secs = service.history[index];
                  final isBest = secs == service.bestTimeSeconds;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isBest
                          ? (isDark
                              ? AppColors.softTeal.withValues(alpha: 0.2)
                              : AppColors.softTeal.withValues(alpha: 0.12))
                          : (isDark
                              ? AppColors.darkCardAlt
                              : AppColors.lightGrayAlt),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBest)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.softTeal),
                          ),
                        Text(
                          _formatShort(secs),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isBest
                                ? AppColors.softTeal
                                : (isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatShort(int secs) {
    final min = secs ~/ 60;
    final sec = secs % 60;
    if (min > 0) return '${min}m ${sec}s';
    return '${sec}s';
  }
}

// ── Control Button ──────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool isDark;
  final bool filled;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.isDark,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingMd,
          ),
          decoration: BoxDecoration(
            color: filled
                ? color.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkCardAlt : AppColors.lightGray),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            border: filled
                ? Border.all(color: color.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: onTap == null ? color.withValues(alpha: 0.4) : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? color.withValues(alpha: 0.4) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
