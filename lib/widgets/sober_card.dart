import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

/// A premium, rounded card widget with soft shadows, entrance animation,
/// and accessibility support — inspired by Calm, Headspace, and Apple Health.
class SoberCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final double? elevation;
  final VoidCallback? onTap;
  final bool hasShadow;
  final Border? border;
  final Gradient? gradient;

  /// Whether to show a subtle hover/press scale effect.
  final bool enableHoverEffect;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  const SoberCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.elevation,
    this.onTap,
    this.hasShadow = true,
    this.border,
    this.gradient,
    this.enableHoverEffect = true,
    this.semanticLabel,
  });

  @override
  State<SoberCard> createState() => _SoberCardState();
}

class _SoberCardState extends State<SoberCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build the base card container first, stored separately so the
    // StatefulBuilder wrapper below doesn't capture a mutated variable
    // (which would cause infinite recursive rebuild → StackOverflowError).
    final Widget baseCard = Container(
      padding: widget.padding ??
          const EdgeInsets.all(AppConstants.spacingLg),
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingXs,
          ),
      decoration: BoxDecoration(
        color: widget.color ?? (isDark ? AppColors.darkCard : AppColors.white),
        borderRadius:
            BorderRadius.circular(widget.borderRadius ?? AppConstants.radiusLg),
        gradient: widget.gradient,
        border: widget.border,
        boxShadow: widget.hasShadow
            ? [
                BoxShadow(
                  color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
                  blurRadius: widget.elevation ?? 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                // Subtle secondary shadow for depth
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark.withValues(alpha: 0.08)
                      : AppColors.shadowAccent.withValues(alpha: 0.04),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    Widget card = baseCard;

    // Hover / tap effect
    if (widget.enableHoverEffect && widget.onTap != null) {
      card = StatefulBuilder(
        builder: (context, setLocalState) {
          return MouseRegion(
            onEnter: (_) => setLocalState(() => _isHovered = true),
            onExit: (_) => setLocalState(() => _isHovered = false),
            child: AnimatedScale(
              scale: _isHovered ? 1.01 : 1.0,
              duration: AppConstants.animationFast,
              child: baseCard,
            ),
          );
        },
      );
    }

    // Tap handling
    if (widget.onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap!();
          },
          borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppConstants.radiusLg),
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.05),
          highlightColor: AppColors.brandPrimary.withValues(alpha: 0.02),
          child: card,
        ),
      );
    }

    // Accessibility
    if (widget.semanticLabel != null) {
      card = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        child: card,
      );
    }

    return card;
  }
}


