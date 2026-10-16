import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// A normal feature card: icon, title, subtitle and a chevron.
///
/// Sits where the locked Pro teaser used to be. It opens the feature directly
/// and uses the brand primary with light-blue accents — no gold, no lock, and
/// no badge.
class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.primary;
    final Color accent = context.accent;

    return SoberCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      semanticLabel: '$title — $subtitle',
      border: Border.all(
        color: accent.withValues(alpha: 0.35),
        width: 1.2,
      ),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Icon(icon, size: 24, color: primary),
          ),
          const SizedBox(width: AppConstants.spacingSm),

          // ── Title + subtitle ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    color: context.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),

          // ── Chevron ───────────────────────────────────────────────────
          Icon(Icons.chevron_right_rounded, size: 22, color: accent),
        ],
      ),
    );
  }
}
