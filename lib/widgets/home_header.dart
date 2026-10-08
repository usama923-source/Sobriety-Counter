import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/widgets/app_logo.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// Section 1 — Header: App name, tagline, greeting, and a small motivational icon.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ────────────────────────────────────────────────
          Text(
            _greeting(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXxs),

          // ── Logo (wordmark is baked into the image) ─────────────────
          const AppLogo(size: 56),
          const SizedBox(height: AppConstants.spacingXxs),

          // ── Tagline ─────────────────────────────────────────────────
          Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              height: 1.3,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
