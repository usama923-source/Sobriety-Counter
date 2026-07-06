import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/services/savings_service.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Section 5 — Money Saved Card.
///
/// Inputs: drinks per day (stepper), cost per drink (slider).
/// Auto-calculates: money saved, drinks avoided, monthly & yearly savings.
/// Animated counters for all values. Persisted via [SavingsService].
class MoneySavedCard extends StatefulWidget {
  final SavingsService savingsService;
  final SobrietyService sobrietyService;

  const MoneySavedCard({
    super.key,
    required this.savingsService,
    required this.sobrietyService,
  });

  @override
  State<MoneySavedCard> createState() => _MoneySavedCardState();
}

class _MoneySavedCardState extends State<MoneySavedCard> {
  bool _showInputs = false;

  @override
  void initState() {
    super.initState();
    _syncDays();
  }

  @override
  void didUpdateWidget(MoneySavedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDays();
  }

  void _syncDays() {
    widget.savingsService.totalDays = widget.sobrietyService.hasQuitDate
        ? widget.sobrietyService.totalDays
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.savingsService;

    return SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  size: 22,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Money Saved',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              // Settings toggle
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showInputs = !_showInputs),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _showInputs ? Icons.close_rounded : Icons.tune_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Input Section ───────────────────────────────────────────
          AnimatedCrossFade(
            duration: AppConstants.animationMed,
            crossFadeState: _showInputs
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildInputs(isDark),
            secondChild: const SizedBox.shrink(),
          ),

          if (_showInputs) const SizedBox(height: AppConstants.spacingLg),

          // ── Total Money Saved (hero) ────────────────────────────────
          Center(
            child: Column(
              children: [
                _AnimatedCurrencyValue(
                  value: s.moneySaved,
                  isDark: isDark,
                ),
                const SizedBox(height: AppConstants.spacingXxs),
                Text(
                  'total saved',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Stat Grid ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.block_rounded,
                  label: 'Drinks Avoided',
                  value: s.drinksAvoided.toDouble(),
                  color: AppColors.skyBlue,
                  isDark: isDark,
                  decimals: 0,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.today_rounded,
                  label: 'Daily Cost',
                  value: s.dailyCost,
                  color: AppColors.softOrange,
                  isDark: isDark,
                  prefix: '\$',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Monthly Savings',
                  value: s.monthlySavings,
                  color: AppColors.softTeal,
                  isDark: isDark,
                  prefix: '\$',
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.date_range_rounded,
                  label: 'Yearly Savings',
                  value: s.yearlySavings,
                  color: AppColors.successGreen,
                  isDark: isDark,
                  prefix: '\$',
                ),
              ),
            ],
          ),

          // ── Daily Rate Summary ──────────────────────────────────────
          const SizedBox(height: AppConstants.spacingMd),
          Center(
            child: Text(
              'Based on ${s.drinksPerDay} drink${s.drinksPerDay == 1 ? '' : 's'} at \$${s.costPerDrink.toStringAsFixed(2)} each',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Inputs UI ─────────────────────────────────────────────────────

  Widget _buildInputs(bool isDark) {
    final s = widget.savingsService;

    return Column(
      children: [
        const SizedBox(height: AppConstants.spacingLg),

        // Drinks per day
        _InputRow(
          label: 'Drinks per day',
          value: '${s.drinksPerDay}',
          onDecrement: () => s.setDrinksPerDay(s.drinksPerDay - 1),
          onIncrement: () => s.setDrinksPerDay(s.drinksPerDay + 1),
          isDark: isDark,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // Cost per drink
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avg. cost per drink',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '\$${s.costPerDrink.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXs),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.successGreen,
                inactiveTrackColor: isDark
                    ? AppColors.darkCardAlt
                    : AppColors.lightGrayAlt,
                thumbColor: AppColors.successGreen,
                overlayColor: AppColors.successGreen.withValues(alpha: 0.15),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: s.costPerDrink,
                min: 0.5,
                max: 50,
                divisions: 99,
                label: '\$${s.costPerDrink.toStringAsFixed(2)}',
                onChanged: (v) => s.setCostPerDrink(v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$0.50',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                        : AppColors.textTertiary.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '\$50.00',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                        : AppColors.textTertiary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── Animated Hero Currency ─────────────────────────────────────────────

class _AnimatedCurrencyValue extends StatelessWidget {
  final double value;
  final bool isDark;

  const _AnimatedCurrencyValue({required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppConstants.animationSlow,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '\$${_formatAmount(value)}',
          key: ValueKey(value.toStringAsFixed(1)),
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w300,
            height: 1.0,
            letterSpacing: -1.0,
            color: AppColors.successGreen,
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

// ── Mini Stat Card ─────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool isDark;
  final String? prefix;
  final int decimals;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.prefix,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlt : AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: AppConstants.animationMed,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              '${prefix ?? ''}${_format(value)}',
              key: ValueKey('${value}_$label'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double amount) {
    if (decimals > 0) return amount.toStringAsFixed(decimals);
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }
}

// ── Input Row with Stepper ─────────────────────────────────────────────

class _InputRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool isDark;

  const _InputRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrement
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardAlt
                          : AppColors.lightGrayAlt,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            AnimatedSwitcher(
              duration: AppConstants.animationFast,
              child: Text(
                value,
                key: ValueKey(value),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            // Increment
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
