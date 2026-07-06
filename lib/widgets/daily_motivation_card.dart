import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/services/quotes_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Section 3 — Daily Motivation Card.
///
/// Displays a quote with New Quote, Favorite (❤️), and Share buttons.
/// Uses [QuotesService] for the quote source, favorites, and daily seed.
class DailyMotivationCard extends StatelessWidget {
  final QuotesService service;

  const DailyMotivationCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quote = service.currentQuote;
    final isFavorite = service.isCurrentFavorite;
    final isDaily = service.isDaily;

    final card = SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.softOrange.withValues(alpha: 0.2)
                      : AppColors.softOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: AppColors.softOrange,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Daily Motivation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isDaily)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.skyBlue.withValues(alpha: 0.15)
                        : AppColors.mint,
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(
                    'Daily',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Quote Mark ──────────────────────────────────────────────
          Center(
            child: Icon(
              Icons.format_quote_rounded,
              size: 36,
              color: isDark
                  ? AppColors.skyBlueLight.withValues(alpha: 0.25)
                  : AppColors.navyBlue.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // ── Quote Text ──────────────────────────────────────────────
          AnimatedSwitcher(
            duration: AppConstants.animationMed,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              quote.text,
              key: ValueKey('quote_${service.shareText}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.6,
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Author ──────────────────────────────────────────────────
          Center(
            child: Text(
              '— ${quote.author}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Action Buttons Row ──────────────────────────────────────
          Row(
            children: [
              // New Quote
              Expanded(
                child: _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'New Quote',
                  onTap: () => service.nextQuote(),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Favorite toggle
              Expanded(
                child: _ActionButton(
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: isFavorite ? 'Favorited' : 'Favorite',
                  iconColor: isFavorite ? AppColors.softRed : null,
                  onTap: () => service.toggleFavorite(),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Share
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () => _share(context, service.shareText),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          // ── Daily Reset Hint ─────────────────────────────────────────
          if (!isDaily)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingSm),
              child: Center(
                child: GestureDetector(
                  onTap: () => service.resetToDaily(),
                  child: Text(
                    'Back to today\'s quote',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return card;
  }

  void _share(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quote copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Small action button used in the quote actions row.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ??
        (isDark ? AppColors.skyBlueLight : AppColors.navyBlue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                : AppColors.lightGray,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
