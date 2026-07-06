import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// Section 11 — Footer: app branding and version info.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textOnDarkSecondary.withValues(alpha: 0.4)
        : AppColors.textTertiary.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXl,
      ),
      child: Column(
        children: [
          // ── Divider ──────────────────────────────────────────────────
          Container(
            height: 1,
            color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── App Info ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.spa_rounded,
                size: 16,
                color: mutedColor,
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXxs),
          Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Support / Links ──────────────────────────────────────────
          Text(
            'If you\'re in crisis, call or text 988 for the Suicide & Crisis Lifeline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Version ─────────────────────────────────────────────────
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
