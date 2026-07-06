import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/models/milestone.dart';

/// Displays a grid of milestone badges with visual completion states.
class MilestoneBadges extends StatelessWidget {
  final List<({Milestone milestone, bool completed})> milestones;

  const MilestoneBadges({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppConstants.spacingXs,
      runSpacing: AppConstants.spacingXs,
      children: milestones.map((item) {
        final completed = item.completed;
        final m = item.milestone;

        return AnimatedContainer(
          duration: AppConstants.animationMed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingXs + 2,
          ),
          decoration: BoxDecoration(
            color: completed
                ? (isDark
                    ? AppColors.successGreen.withValues(alpha: 0.2)
                    : AppColors.successGreen.withValues(alpha: 0.12))
                : (isDark
                    ? AppColors.darkCardAlt
                    : AppColors.lightGrayAlt),
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            border: completed
                ? Border.all(
                    color: AppColors.successGreen.withValues(alpha: 0.4),
                    width: 1.2,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed ? m.completedIcon : m.icon,
                size: 16,
                color: completed
                    ? AppColors.successGreen
                    : (isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textTertiary),
              ),
              const SizedBox(width: AppConstants.spacingXxs + 2),
              Text(
                m.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: completed ? FontWeight.w700 : FontWeight.w500,
                  color: completed
                      ? AppColors.successGreen
                      : (isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textTertiary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
