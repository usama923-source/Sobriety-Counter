import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Weight Entry Model ─────────────────────────────────────────────────

class _WeightEntry {
  final DateTime date;
  final double weight;

  _WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'weight': weight,
      };

  factory _WeightEntry.fromJson(Map<String, dynamic> json) => _WeightEntry(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        weight: (json['weight'] as num).toDouble(),
      );
}

// ── Unit Enum ────────────────────────────────────────────────────────────

enum _WeightUnit { kg, lbs }

// ── Screen ───────────────────────────────────────────────────────────────

/// Weight Tracker screen — track your weight transformation since quitting.
///
/// Set a goal weight and current weight, log daily entries, and see
/// progress with a motivational message about weight lost.
class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  // ── Keys ────────────────────────────────────────────────────────────
  static const String _goalWeightKey = 'goal_weight';
  static const String _currentWeightKey = 'current_weight';
  static const String _weightLogKey = 'weight_log';

  // ── State ───────────────────────────────────────────────────────────
  _WeightUnit _unit = _WeightUnit.kg;
  double? _goalWeight;
  double? _currentWeight;
  List<_WeightEntry> _weightLog = [];
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();

  // ── Unit helpers ────────────────────────────────────────────────────
  String get _unitLabel => _unit == _WeightUnit.kg ? 'kg' : 'lbs';

  double? get _firstLoggedWeight => _weightLog.isNotEmpty
      ? _weightLog.first.weight
      : _currentWeight;

  double? get _weightLost {
    if (_firstLoggedWeight == null || _currentWeight == null) return null;
    return _firstLoggedWeight! - _currentWeight!;
  }

  double? get _progress {
    if (_goalWeight == null || _currentWeight == null) return null;
    final start = _firstLoggedWeight ?? _currentWeight!;
    if (start <= _goalWeight!) return 1.0; // Already at or past goal
    final total = start - _goalWeight!;
    final soFar = start - _currentWeight!;
    return (soFar / total).clamp(0.0, 1.0);
  }

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  // ── Data Persistence ────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goalWeight = prefs.getDouble(_goalWeightKey);
      _currentWeight = prefs.getDouble(_currentWeightKey);

      final logJson = prefs.getString(_weightLogKey);
      if (logJson != null) {
        final list = jsonDecode(logJson) as List<dynamic>;
        _weightLog =
            list.map((e) => _WeightEntry.fromJson(e as Map<String, dynamic>)).toList()
              ..sort((a, b) => a.date.compareTo(b.date));
      }

      if (_goalWeight != null) {
        _goalController.text = _goalWeight!.toStringAsFixed(1);
      }
      if (_currentWeight != null) {
        _currentController.text = _currentWeight!.toStringAsFixed(1);
      }

    });
  }

  Future<void> _saveGoalWeight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalWeightKey, weight);
    setState(() => _goalWeight = weight);
  }

  Future<void> _saveCurrentWeight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_currentWeightKey, weight);
    setState(() => _currentWeight = weight);
  }

  Future<void> _saveWeightLog() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_weightLog.map((e) => e.toJson()).toList());
    await prefs.setString(_weightLogKey, json);
  }

  // ── Actions ─────────────────────────────────────────────────────────

  void _setGoalWeight() {
    final text = _goalController.text.trim();
    if (text.isEmpty) return;
    final weight = double.tryParse(text);
    if (weight == null || weight <= 0) return;

    HapticFeedback.mediumImpact();
    _saveGoalWeight(weight);
    _clearFocus();
  }

  void _setCurrentWeight() {
    final text = _currentController.text.trim();
    if (text.isEmpty) return;
    final weight = double.tryParse(text);
    if (weight == null || weight <= 0) return;

    HapticFeedback.mediumImpact();
    _saveCurrentWeight(weight);
    _clearFocus();
  }

  void _logWeight() {
    if (_currentWeight == null) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _weightLog.add(_WeightEntry(
        date: DateTime.now(),
        weight: _currentWeight!,
      ));
    });
    _saveWeightLog();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged $_currentWeight$_unitLabel',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
      ),
    );
  }

  void _toggleUnit() {
    setState(() {
      final wasKg = _unit == _WeightUnit.kg;
      _unit = wasKg ? _WeightUnit.lbs : _WeightUnit.kg;

      // Convert stored values
      if (_goalWeight != null) {
        _goalWeight = wasKg ? _goalWeight! * 2.20462 : _goalWeight! / 2.20462;
        _goalController.text = _goalWeight!.toStringAsFixed(1);
        _saveGoalWeight(_goalWeight!);
      }
      if (_currentWeight != null) {
        _currentWeight = wasKg
            ? _currentWeight! * 2.20462
            : _currentWeight! / 2.20462;
        _currentController.text = _currentWeight!.toStringAsFixed(1);
        _saveCurrentWeight(_currentWeight!);
      }
      // Convert weight log entries
      for (var i = 0; i < _weightLog.length; i++) {
        _weightLog[i] = _WeightEntry(
          date: _weightLog[i].date,
          weight: wasKg
              ? _weightLog[i].weight * 2.20462
              : _weightLog[i].weight / 2.20462,
        );
      }
      _saveWeightLog();
    });
    HapticFeedback.lightImpact();
  }

  void _clearFocus() {
    FocusScope.of(context).unfocus();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        color: AppColors.softTeal.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.monitor_weight_rounded,
                        size: 34,
                        color: AppColors.softTeal,
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
                                isSelected: _unit == _WeightUnit.kg,
                                onTap: _unit == _WeightUnit.lbs
                                    ? _toggleUnit
                                    : null,
                                isDark: isDark,
                              ),
                              _UnitToggleChip(
                                label: 'lbs',
                                isSelected: _unit == _WeightUnit.lbs,
                                onTap: _unit == _WeightUnit.kg
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
              if (_goalWeight != null && _currentWeight != null) ...[
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
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 20,
                            color: AppColors.successGreen,
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
                          value: _progress,
                          minHeight: 14,
                          backgroundColor: AppColors.successGreen.withValues(
                            alpha: isDark ? 0.12 : 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progress == 1.0
                                ? AppColors.successGreen
                                : AppColors.softTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),

                      // ── Progress Labels ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentWeight!.toStringAsFixed(1)}$_unitLabel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_goalWeight!.toStringAsFixed(1)}$_unitLabel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingLg),

                      // ── Weight Lost Message ─────────────────────────
                      if (_weightLost != null && _weightLost! > 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.successGreen.withValues(
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
                                  color: AppColors.successGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 22,
                                  color: AppColors.successGreen,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You\'ve lost ${_weightLost!.toStringAsFixed(1)}$_unitLabel since quitting!',
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
                      if (_progress == 1.0) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.successGreen.withValues(
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
                                  color: AppColors.successGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.celebration_rounded,
                                  size: 22,
                                  color: AppColors.successGreen,
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
                      if ((_weightLost == null || _weightLost! <= 0) &&
                          _progress != 1.0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.skyBlue.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.skyBlue.withValues(
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
                                  color: AppColors.skyBlue.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 22,
                                  color: AppColors.skyBlue,
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
              if (_currentWeight != null) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logWeight,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      'Log $_currentWeight$_unitLabel',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softTeal,
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
              if (_weightLog.isNotEmpty) ...[
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
                            color: AppColors.navyBlue,
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
                            '${_weightLog.length} entry${_weightLog.length == 1 ? '' : 'ies'}',
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
                      ..._weightLog.reversed.take(10).map((entry) {
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
                                  '${entry.weight.toStringAsFixed(1)}$_unitLabel',
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
                      if (_weightLog.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${_weightLog.length - 10} more entries',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.skyBlueLight
                                  : AppColors.navyBlue,
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
          Expanded(                      child: Column(
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
                                                ? AppColors.navyBlueLight
                                                : AppColors.navyBlue,
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
              ? (isDark ? AppColors.navyBlueLight : AppColors.navyBlue)
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
