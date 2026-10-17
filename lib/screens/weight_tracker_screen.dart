import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/weight_tracker_provider.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

// ── Screen ───────────────────────────────────────────────────────────────

/// Weight Tracker screen — track your weight transformation since quitting.
///
/// Set a goal weight and current weight, log daily entries, and see
/// progress with a motivational message about weight lost.
///
/// Persisted data (goal, current weight, and the weight log) lives in
/// [weightTrackerProvider]; only unit selection and text input stay local.
class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() =>
      _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen> {
  // ── Local UI State ──────────────────────────────────────────────────
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();

  // ── Unit helpers ────────────────────────────────────────────────────

  /// Display unit — owned and persisted by the provider; storage stays in kg.
  WeightUnit get _unit => ref.read(weightTrackerProvider).unit;

  String get _unitLabel => _unit.label;

  /// Formats a canonical kilogram [weight] in the active display unit.
  ///
  /// Whole numbers drop the decimal ("80 kg") while fractions keep one
  /// digit ("80.5 kg").
  String _formatWeight(double weight) {
    final value = _unit.fromKg(weight);
    final rounded = double.parse(value.toStringAsFixed(1));
    final text = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '$text $_unitLabel';
  }

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Populate the text fields once persisted values finish loading.
    ref.listenManual(weightTrackerProvider, (previous, next) {
      if (next.goalWeight != null && _goalController.text.isEmpty) {
        _goalController.text =
            next.unit.fromKg(next.goalWeight!).toStringAsFixed(1);
      }
      if (next.currentWeight != null && _currentController.text.isEmpty) {
        _currentController.text =
            next.unit.fromKg(next.currentWeight!).toStringAsFixed(1);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────

  void _setGoalWeight() {
    final text = _goalController.text.trim();
    if (text.isEmpty) return;
    final entered = double.tryParse(text);
    if (entered == null || entered <= 0) return;

    HapticFeedback.mediumImpact();
    // The input is in the display unit; storage is always kilograms.
    ref.read(weightTrackerProvider.notifier).setGoalWeight(_unit.toKg(entered));
    _clearFocus();
  }

  void _setCurrentWeight() {
    final text = _currentController.text.trim();
    if (text.isEmpty) return;
    final entered = double.tryParse(text);
    if (entered == null || entered <= 0) return;

    HapticFeedback.mediumImpact();
    ref
        .read(weightTrackerProvider.notifier)
        .setCurrentWeight(_unit.toKg(entered));
    _clearFocus();
  }

  void _logWeight() {
    final currentWeight = ref.read(weightTrackerProvider).currentWeight;
    if (currentWeight == null) return;

    HapticFeedback.heavyImpact();
    ref.read(weightTrackerProvider.notifier).logWeight();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${_formatWeight(currentWeight)}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
      ),
    );
  }

  void _toggleUnit() {
    final next = _unit == WeightUnit.kg ? WeightUnit.lbs : WeightUnit.kg;
    // Stored weights stay canonical kilograms — only the display changes.
    ref.read(weightTrackerProvider.notifier).setUnit(next);

    final state = ref.read(weightTrackerProvider);
    if (state.goalWeight != null) {
      _goalController.text =
          next.fromKg(state.goalWeight!).toStringAsFixed(1);
    }
    if (state.currentWeight != null) {
      _currentController.text =
          next.fromKg(state.currentWeight!).toStringAsFixed(1);
    }

    HapticFeedback.lightImpact();
  }

  void _clearFocus() {
    FocusScope.of(context).unfocus();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(weightTrackerProvider);
    final goalWeight = state.goalWeight;
    final currentWeight = state.currentWeight;
    final weightLog = state.weightLog;
    final progress = state.progress;
    final goalAchieved = state.goalAchieved;
    final weightLost = state.weightLost;

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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Weight Tracker',
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
              // ── Header Card ──────────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingLg,
                  horizontal: AppConstants.spacingLg,
                ),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.monitor_weight_rounded,
                        size: 34,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Track Your Transformation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Set your goals and watch your progress\nas you transform your body and mind.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Weight Input Cards ────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: Column(
                  children: [
                    // ── Unit Toggle ────────────────────────────────────
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightGrayAlt,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusFull,
                            ),
                          ),
                          child: Row(
                            children: [
                              _UnitToggleChip(
                                label: 'kg',
                                isSelected: state.unit == WeightUnit.kg,
                                onTap: state.unit == WeightUnit.lbs
                                    ? _toggleUnit
                                    : null,
                                isDark: isDark,
                              ),
                              _UnitToggleChip(
                                label: 'lbs',
                                isSelected: state.unit == WeightUnit.lbs,
                                onTap: state.unit == WeightUnit.kg
                                    ? _toggleUnit
                                    : null,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Goal Weight ────────────────────────────────────
                    _WeightInputTile(
                      icon: Icons.flag_rounded,
                      label: 'Goal Weight',
                      controller: _goalController,
                      unitLabel: _unitLabel,
                      isDark: isDark,
                      onSave: _setGoalWeight,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // ── Current Weight ─────────────────────────────────
                    _WeightInputTile(
                      icon: Icons.monitor_weight_rounded,
                      label: 'Current Weight',
                      controller: _currentController,
                      unitLabel: _unitLabel,
                      isDark: isDark,
                      onSave: _setCurrentWeight,
                    ),
                  ],
                ),
              ),

              // ── Progress Section ─────────────────────────────────────
              if (goalWeight != null && currentWeight != null) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SoberCard(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: isDark
                      ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                      : AppColors.white,
                  hasShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Progress Header ─────────────────────────────
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.brandLightBlue
                                : AppColors.brandPrimary,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            'Your Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingLg),

                      // ── Progress Bar ────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusFull,
                        ),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                          backgroundColor: AppColors.brandPrimary.withValues(
                            alpha: isDark ? 0.12 : 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goalAchieved
                                ? AppColors.brandLightBlue
                                : AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),

                      // ── Progress Labels ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatWeight(currentWeight),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatWeight(goalWeight),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingLg),

                      // ── Weight Lost Message ─────────────────────────
                      if (weightLost != null && weightLost > 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.brandPrimary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 22,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You\'ve lost ${_formatWeight(weightLost)} since quitting!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        color: isDark
                                            ? AppColors.textOnDark
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Keep going, every step counts.',
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
                            ],
                          ),
                        ),
                      ],

                      // ── At Goal Message ─────────────────────────────
                      if (goalAchieved) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.brandPrimary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.celebration_rounded,
                                  size: 22,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),
                              Expanded(
                                child: Text(
                                  'Congratulations! You\'ve reached your goal weight! 🎉',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Initial Progress Message ────────────────────
                      if (!goalAchieved &&
                          (weightLost == null || weightLost <= 0)) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.brandPrimary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 22,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),
                              Expanded(
                                child: Text(
                                  'Every journey begins with a single step. Log your weight to see your progress!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Log Weight Button ────────────────────────────────────
              if (currentWeight != null) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logWeight,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      'Log ${_formatWeight(currentWeight)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
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
              ],

              // ── Weight Log History ──────────────────────────────────
              if (weightLog.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SoberCard(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: isDark
                      ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                      : AppColors.white,
                  hasShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            'Weight Log',
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
                            '${weightLog.length} entry${weightLog.length == 1 ? '' : 'ies'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      ...weightLog.reversed.take(10).map((entry) {
                        final months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                        ];
                        final dateStr =
                            '${months[entry.date.month - 1]} ${entry.date.day}';
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingXs,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingMd,
                              vertical: AppConstants.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightGray,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSm,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatWeight(entry.weight),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (weightLog.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${weightLog.length - 10} more entries',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.brandLightBlue
                                  : AppColors.brandPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weight Input Tile ────────────────────────────────────────────────────

class _WeightInputTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String unitLabel;
  final bool isDark;
  final VoidCallback onSave;

  const _WeightInputTile({
    required this.icon,
    required this.label,
    required this.controller,
    required this.unitLabel,
    required this.isDark,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '0.0',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                    .withValues(alpha: 0.3)
                                : AppColors.textTertiary
                                    .withValues(alpha: 0.4),
                          ),
                          suffixText: unitLabel,
                          suffixStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        onSubmitted: (_) => onSave(),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSave,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppConstants.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.brandPrimaryLight
                                : AppColors.brandPrimary,
                            borderRadius:
                                BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unit Toggle Chip ─────────────────────────────────────────────────────

class _UnitToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;

  const _UnitToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
