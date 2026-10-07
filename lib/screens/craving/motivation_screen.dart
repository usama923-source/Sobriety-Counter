import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/quotes_provider.dart';
import 'package:quit_drinking/data/quotes.dart';
import 'package:quit_drinking/services/quotes_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Motivation screen — displays uplifting sobriety quotes to help
/// users push through a craving. Includes random quote cycling,
/// favorites, and copy-to-clipboard share.
///
/// Uses the shared [QuotesService] so favorites persist across sessions
/// and stay in sync with the Daily Motivation card on the home screen.
class MotivationScreen extends ConsumerStatefulWidget {
  const MotivationScreen({super.key});

  @override
  ConsumerState<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends ConsumerState<MotivationScreen> {
  bool _showCopiedConfirmation = false;

  QuotesService get _service => ref.read(quotesServiceProvider);

  Quote get _currentQuote => _service.currentQuote;
  bool get _isFavorite => _service.isCurrentFavorite;
  Set<int> get _favorites => _service.favoriteIndices;

  void _nextQuote() {
    _service.nextQuote();
    HapticFeedback.lightImpact();
  }

  void _toggleFavorite() {
    _service.toggleFavorite();
    HapticFeedback.mediumImpact();
  }

  void _copyQuote() {
    Clipboard.setData(
      ClipboardData(text: '"${_currentQuote.text}" — ${_currentQuote.author}'),
    );
    setState(() => _showCopiedConfirmation = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopiedConfirmation = false);
    });
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quote = ref.watch(quotesServiceProvider).currentQuote;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Read Motivation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingLg,
          ),
          child: Column(
            children: [
              // ── Header Icon Card ──────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingXxl,
                  horizontal: AppConstants.spacingLg,
                ),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.softTeal.withValues(
                          alpha: isDark ? 0.15 : 0.1,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: AppColors.softTeal,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text(
                      'Inspiration for the Moment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Let these words strengthen your resolve.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Quote Card ─────────────────────────────────────────────
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
                child: SoberCard(
                  key: ValueKey('quote_${quote.text}'),
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: isDark
                      ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                      : AppColors.white,
                  hasShadow: true,
                  child: Column(
                    children: [
                      // Quote mark
                      Icon(
                        Icons.format_quote_rounded,
                        size: 48,
                        color: AppColors.softTeal.withValues(
                          alpha: isDark ? 0.2 : 0.15,
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingSm),

                      // Quote text
                      Text(
                        quote.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingMd),

                      // Author
                      Text(
                        '— ${quote.author}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Action Buttons ─────────────────────────────────────────
              Row(
                children: [
                  // New Quote
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'New Quote',
                      onTap: _nextQuote,
                      isDark: isDark,
                      color: AppColors.navyBlue,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),

                  // Favorite toggle
                  Expanded(
                    child: _ActionButton(
                      icon: _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: _isFavorite ? 'Favorited' : 'Favorite',
                      onTap: _toggleFavorite,
                      isDark: isDark,
                      color: _isFavorite
                          ? AppColors.softRed
                          : AppColors.navyBlue,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),

                  // Copy / Share
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      onTap: _copyQuote,
                      isDark: isDark,
                      color: AppColors.navyBlue,
                    ),
                  ),
                ],
              ),

              // ── Copied Confirmation ──────────────────────────────────
              if (_showCopiedConfirmation)
                Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingMd),
                  child: AnimatedSwitcher(
                    duration: AppConstants.animationFast,
                    child: Container(
                      key: const ValueKey('copied'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                        vertical: AppConstants.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color:
                              AppColors.softTeal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.softTeal,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            'Quote copied to clipboard!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Favorite Quotes Section ───────────────────────────────
              if (_favorites.isNotEmpty)
                SoberCard(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: isDark
                      ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                      : Colors.white,
                  hasShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: AppColors.softRed,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            'Your Favorites',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_favorites.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      ..._favorites.take(3).map((index) {
                        final favQuote = allQuotes[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingXs,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _service.showQuote(index),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppConstants.spacingMd,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightGray,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                              ),
                              child: Text(
                                '"${favQuote.text}"',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_favorites.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${_favorites.length - 3} more favorites',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.softTealLight
                                  : AppColors.navyBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Button ───────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(
              color: color.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
