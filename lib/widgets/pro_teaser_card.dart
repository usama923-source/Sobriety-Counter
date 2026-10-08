import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';

/// A reusable locked Pro teaser card.
///
/// Shows an icon + title + subtitle with a gold 🔒 "PRO" badge and a teal
/// border on a navy-blue-tinted background. Tapping it opens the Pro Upgrade
/// sheet.
class ProTeaserCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const ProTeaserCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.primary.withValues(alpha: 0.08),
      surfaceTintColor: context.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.primary, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // ── Icon ──────────────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: context.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // ── Title + subtitle ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Gold 🔒 "PRO" badge ───────────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🔒PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
