import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A premium bottom sheet shown when any Pro feature is tapped.
///
/// Displays a gold crown icon, title, subtitle, a list of Pro features,
/// and a gold-gradient "Unlock Pro — \$2.99" button. On confirm, sets
/// the SharedPreferences key "is_pro" to true.
class ProUpgradeSheet extends StatelessWidget {
  final bool isDark;

  const ProUpgradeSheet({
    super.key,
    required this.isDark,
  });

  /// Show the upgrade bottom sheet from any [context].
  ///
  /// Returns `true` if the user upgraded, `false` otherwise.
  static Future<bool> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => ProUpgradeSheet(isDark: isDark),
    ).then((result) => result ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return SoberCard(
      margin: EdgeInsets.zero,
      borderRadius: AppConstants.radiusXl,
      hasShadow: false,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingXxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ───────────────────────────────────────
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

          // ── Gold Crown Icon ───────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Title ─────────────────────────────────────────────
          Text(
            'Unlock Pro Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXxs),

          // ── Subtitle ──────────────────────────────────────────
          Text(
            'One-time payment, yours forever',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // ── Feature List ──────────────────────────────────────
          _FeatureRow(
            emoji: '🤖',
            title: 'AI Friend',
            subtitle: '24/7 emotional support',
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _FeatureRow(
            emoji: '🧠',
            title: 'Memory Game',
            subtitle: 'Beat cravings with focus',
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _FeatureRow(
            emoji: '⚖️',
            title: 'Weight Tracker',
            subtitle: 'Track your transformation',
            isDark: isDark,
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // ── Unlock Button (Gold Gradient) ─────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _handleUpgrade(context),
              icon: const Icon(Icons.star_rounded, size: 20),
              label: const Text('Unlock Pro — \$2.99'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMd,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // ── Maybe Later ───────────────────────────────────────
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
    );
  }

  Future<void> _handleUpgrade(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', true);

    if (!context.mounted) return;

    Navigator.of(context).pop(true);
  }
}

// ── Feature Row ────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isDark;

  const _FeatureRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Emoji circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardAlt.withValues(alpha: 0.6)
                : AppColors.lightGray,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
