import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/widgets/app_logo.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// Section 1 — Header: a circular logo with the wordmark and tagline.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor =
        isDark ? AppColors.brandLightBlue : AppColors.brandPrimary;
    final secondaryColor = isDark
        ? AppColors.textOnDarkSecondary
        : AppColors.secondaryTextLight;

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
              color: secondaryColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // ── Logo + wordmark ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppLogo(size: 56),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wordmark — theme text style, brand colored.
                    Text(
                      'QUITDRINK',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (Theme.of(context).textTheme.titleMedium ??
                              const TextStyle())
                          .copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Tagline — small secondary text.
                    Text(
                      AppConstants.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
