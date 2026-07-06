import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// A clean, branded elevated button used throughout Sober Today.
class SoberButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;
  final Color? textColor;
  final double? height;

  const SoberButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.color,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ??
        (isDark ? AppColors.skyBlueLight : AppColors.navyBlue);
    final fgColor = textColor ??
        (isDark ? AppColors.navyBlueDark : AppColors.white);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.4),
          disabledForegroundColor: fgColor.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: fgColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppConstants.iconMd),
                    const SizedBox(width: AppConstants.spacingSm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// A ghost-style outlined button.
class SoberOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final Color? color;
  final double? height;

  const SoberOutlineButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isFullWidth = true,
    this.color,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = color ??
        (isDark ? AppColors.skyBlueLight : AppColors.navyBlue);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: borderColor,
          side: BorderSide(color: borderColor, width: 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppConstants.iconMd),
              const SizedBox(width: AppConstants.spacingSm),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// A compact text button for secondary actions.
class SoberTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double fontSize;

  const SoberTextButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = color ??
        (isDark ? AppColors.skyBlueLight : AppColors.navyBlue);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: btnColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: AppConstants.spacingXs,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppConstants.iconSm),
            const SizedBox(width: AppConstants.spacingXxs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
