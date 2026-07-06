import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_button.dart';

/// A calming empty state widget with entrance animation.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationSlow,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 64,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.3)
                      : AppColors.textTertiary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  SoberButton(
                    label: widget.actionLabel!,
                    onPressed: widget.onAction,
                    isFullWidth: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
