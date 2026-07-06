import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// A styled section header with title and optional action button.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingMd,
        right: AppConstants.spacingMd,
        bottom: AppConstants.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.skyBlueLight
                          : AppColors.navyBlue,
                    ),
                  ),
                  if (actionIcon != null) ...[
                    const SizedBox(width: AppConstants.spacingXxs),
                    Icon(
                      actionIcon,
                      size: AppConstants.iconSm,
                      color: isDark
                          ? AppColors.skyBlueLight
                          : AppColors.navyBlue,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
