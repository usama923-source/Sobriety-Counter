import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// A small reusable app logo: logo asset with the app name beside it.
///
/// Used by the drawer header and the home screen header. The size is the
/// icon diameter; the text stays at the same typographic scale.
class AppLogo extends StatelessWidget {
  final double size; // icon diameter in logical pixels
  final bool isDark;

  const AppLogo({super.key, this.size = 48, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.navyBlue
                    : AppColors.navyBlue.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                size: 32,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
