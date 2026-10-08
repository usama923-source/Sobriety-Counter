import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/screens/craving/craving_actions_screen.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Craving Help Card.
///
/// A calming card that reassures the user cravings pass, with a single
/// full-width pill button that opens the Craving Actions screen.
class CravingHelpCard extends StatelessWidget {
  const CravingHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      enableHoverEffect: false,
      color: isDark
          ? AppColors.softTeal.withValues(alpha: 0.06)
          : AppColors.mintLight,
      border: Border.all(
        color: AppColors.softTeal.withValues(alpha: 0.2),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.healing_rounded,
                  size: 22,
                  color: AppColors.softTeal,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Craving Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // ── Description ───────────────────────────────────────────
          Text(
            'Cravings are normal and they pass. Take a deep breath and try one of these calming activities.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),

          // ── Crisis note ───────────────────────────────────────────
          Text(
            "If you're in crisis, please contact a medical professional or call a helpline.",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _CalmCravingButton(
              onTap: () => _openCravingActions(context),
            ),
          ),
        ],
      ),
    );
  }

  void _openCravingActions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CravingActionsScreen(),
      ),
    );
  }
}

// ── Calming Craving Button ──────────────────────────────────────────────

class _CalmCravingButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CalmCravingButton({required this.onTap});

  @override
  State<_CalmCravingButton> createState() => _CalmCravingButtonState();
}

class _CalmCravingButtonState extends State<_CalmCravingButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // The Material owns the solid color and rounded shape, and clips the ink,
    // so the ripple/highlight paints ON the button instead of behind it.
    return SizedBox(
      width: double.infinity,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: context.primary,
          borderRadius: BorderRadius.circular(50),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              // Let the press feedback play before navigating away.
              await Future.delayed(const Duration(milliseconds: 150));
              if (mounted) widget.onTap();
            },
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: BorderRadius.circular(50),
            splashColor: Colors.white.withValues(alpha: 0.35),
            highlightColor: Colors.white.withValues(alpha: 0.18),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.self_improvement_rounded,
                    size: 20,
                    color: context.onPrimary,
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Flexible(
                    child: Text(
                      'Tap for calming activities',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: context.onPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
