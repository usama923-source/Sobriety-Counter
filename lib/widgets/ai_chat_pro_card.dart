import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/screens/ai_chat_screen.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section 2.5 — AI Friend Pro Card.
///
/// A premium card that promotes the "Talk to Your AI Friend" Pro feature.
/// Tapping checks the "is_pro" SharedPreferences key — Pro users navigate
/// directly to [AIChatScreen]; non-Pro users see an upgrade bottom sheet.
class AIChatProCard extends StatelessWidget {
  const AIChatProCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      onTap: () => _handleAIFriend(context),
      enableHoverEffect: true,
      gradient: LinearGradient(
        colors: isDark
            ? [
                AppColors.darkCard,
                AppColors.navyBlue.withValues(alpha: 0.3),
              ]
            : [
                AppColors.white,
                AppColors.navyBlue.withValues(alpha: 0.04),
              ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row with Pro Badge ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 22,
                  color: AppColors.navyBlue,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talk to Your AI Friend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color:
                            isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Available 24/7 whenever you need support',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppConstants.spacingXs),

              // 🔒 Pro Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🔒',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Pro',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.navyBlueDark
                            : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Tap hint ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                'Tap to start a conversation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.6)
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pro Check Logic ───────────────────────────────────────────────

  Future<void> _handleAIFriend(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro') ?? false;

    if (!context.mounted) return;

    if (isPro) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AIChatScreen(),
        ),
      );
    } else {
      _showProUpgradeSheet(context, prefs);
    }
  }

  void _showProUpgradeSheet(BuildContext context, SharedPreferences prefs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _ProUpgradeSheet(
        isDark: isDark,
        onUpgrade: () async {
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (ctx2) => AlertDialog(
              backgroundColor:
                  isDark ? AppColors.darkSurfaceAlt : AppColors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
              title: Text(
                'Confirm Upgrade',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              content: Text(
                'Upgrade to Pro for \$4.99/month?\n\nIncludes:\n• AI Friend Chat\n• Premium features\n• Early access to new tools',
                style: TextStyle(
                  height: 1.5,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx2, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSm),
                    ),
                  ),
                  child: const Text('Upgrade Now'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await prefs.setBool('is_pro', true);
            if (ctx.mounted) {
              Navigator.of(ctx).pop(); // Close upgrade sheet
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AIChatScreen(),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ── Pro Upgrade Bottom Sheet ──────────────────────────────────────────

class _ProUpgradeSheet extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onUpgrade;

  const _ProUpgradeSheet({
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingXxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textOnDarkSecondary.withValues(alpha: 0.3)
                    : AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Pro icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Title
            Text(
              'Pro Feature',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Description
            Text(
              'Talk to an AI Friend is a Pro feature.\nUpgrade to unlock AI-powered conversations\nto help you through your journey.',
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
            const SizedBox(height: AppConstants.spacingXl),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.star_rounded, size: 20),
                label: const Text('Upgrade to Pro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Maybe later
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
