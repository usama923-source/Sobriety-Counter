import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the persisted weight-tracker data.
///
/// The provider owns the goal weight, the current weight, and the weight log
/// (all persisted in SharedPreferences). UI-only state (selected unit, text
/// controllers, focus) stays in the screen's setState.
final weightTrackerProvider =
    StateNotifierProvider<WeightTrackerNotifier, WeightTrackerState>((ref) {
  return WeightTrackerNotifier();
});

/// A single logged weight entry.
class WeightEntry {
  final DateTime date;
  final double weight;

  const WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'weight': weight,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        weight: (json['weight'] as num).toDouble(),
      );
}

/// The state held by the weight-tracker provider.
class WeightTrackerState {
  final double? goalWeight;
  final double? currentWeight;
  final double? startWeight;
  final List<WeightEntry> weightLog;
  final bool isLoading;

  const WeightTrackerState({
    this.goalWeight,
    this.currentWeight,
    this.startWeight,
    this.weightLog = const [],
    this.isLoading = true,
  });

  /// First logged weight, falling back to the current weight.
  double? get firstLoggedWeight =>
      weightLog.isNotEmpty ? weightLog.first.weight : currentWeight;

  /// The weight the user was at when they set their goal.
  ///
  /// Falls back to the first logged weight (or the current weight) for data
  /// saved before this field existed.
  double? get startWeightValue =>
      startWeight ?? firstLoggedWeight ?? currentWeight;

  /// True when the goal is lower than the starting weight (a loss goal).
  bool get isLossGoal {
    final start = startWeight;
    if (start == null || goalWeight == null) return false;
    return goalWeight! < start;
  }

  /// True when the goal is higher than the starting weight (a gain goal).
  bool get isGainGoal {
    final start = startWeight;
    if (start == null || goalWeight == null) return false;
    return goalWeight! > start;
  }

  /// Total weight lost since the starting weight (negative for a gain goal).
  double? get weightLost {
    final start = startWeightValue;
    if (start == null || currentWeight == null) return null;
    return start - currentWeight!;
  }

  /// Progress from the start weight toward the goal, clamped to 0..1.
  ///
  /// Returns 0 when there is no distance to travel (goal == start).
  double? get progress {
    if (goalWeight == null || currentWeight == null) return null;
    final start = startWeightValue;
    if (start == null) return null;
    final total = (goalWeight! - start).abs();
    if (total == 0) return 0.0;
    final moved =
        isGainGoal ? currentWeight! - start : start - currentWeight!;
    return (moved / total).clamp(0.0, 1.0);
  }

  /// Whether the current weight has actually reached the goal.
  bool get goalAchieved {
    if (goalWeight == null || currentWeight == null) return false;
    if (isLossGoal) return currentWeight! <= goalWeight!;
    if (isGainGoal) return currentWeight! >= goalWeight!;
    return false; // goal == start: nothing to progress toward
  }

  WeightTrackerState copyWith({
    double? goalWeight,
    double? currentWeight,
    double? startWeight,
    List<WeightEntry>? weightLog,
    bool? isLoading,
  }) {
    return WeightTrackerState(
      goalWeight: goalWeight ?? this.goalWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      startWeight: startWeight ?? this.startWeight,
      weightLog: weightLog ?? this.weightLog,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// The notifier that manages weight-tracker state and persistence.
class WeightTrackerNotifier extends StateNotifier<WeightTrackerState> {
  WeightTrackerNotifier() : super(const WeightTrackerState()) {
    _loadData();
  }

  static const String _goalWeightKey = 'goal_weight';
  static const String _currentWeightKey = 'current_weight';
  static const String _startWeightKey = 'start_weight';
  static const String _weightLogKey = 'weight_log';

  /// Load persisted values from SharedPreferences and update state.
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    var log = <WeightEntry>[];
    final logJson = prefs.getString(_weightLogKey);
    if (logJson != null) {
      try {
        final list = jsonDecode(logJson) as List<dynamic>;
        log = list
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      } catch (e) {
        // Corrupt or unexpected log data — start with an empty log instead
        // of crashing the screen on open.
        log = [];
        debugPrint('[WeightTracker] Failed to parse weight log: $e');
      }
    }

    state = WeightTrackerState(
      goalWeight: prefs.getDouble(_goalWeightKey),
      currentWeight: prefs.getDouble(_currentWeightKey),
      startWeight: prefs.getDouble(_startWeightKey),
      weightLog: log,
      isLoading: false,
    );
  }

  /// Set and persist the goal weight.
  ///
  /// The current weight at this moment is captured as the explicit starting
  /// weight, so direction (loss vs gain) is measured against it.
  Future<void> setGoalWeight(double weight) async {
    final start = state.currentWeight;
    state = state.copyWith(goalWeight: weight, startWeight: start);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalWeightKey, weight);
    if (state.startWeight != null) {
      await prefs.setDouble(_startWeightKey, state.startWeight!);
    }
  }

  /// Set and persist the current weight.
  Future<void> setCurrentWeight(double weight) async {
    state = state.copyWith(currentWeight: weight);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_currentWeightKey, weight);
  }

  /// Append the current weight to the log and persist it.
  Future<void> logWeight() async {
    final current = state.currentWeight;
    if (current == null) return;

    final updated = [
      ...state.weightLog,
      WeightEntry(date: DateTime.now(), weight: current),
    ];
    state = state.copyWith(weightLog: updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _weightLogKey,
      jsonEncode(state.weightLog.map((e) => e.toJson()).toList()),
    );
  }

  /// Multiply every stored weight by [factor] (kg <-> lbs conversion) and
  /// persist the converted values.
  Future<void> convertStoredWeights(double factor) async {
    final convertedLog = state.weightLog
        .map((e) => WeightEntry(date: e.date, weight: e.weight * factor))
        .toList();

    state = state.copyWith(
      goalWeight: state.goalWeight == null ? null : state.goalWeight! * factor,
      currentWeight:
          state.currentWeight == null ? null : state.currentWeight! * factor,
      startWeight:
          state.startWeight == null ? null : state.startWeight! * factor,
      weightLog: convertedLog,
    );

    final prefs = await SharedPreferences.getInstance();
    if (state.goalWeight != null) {
      await prefs.setDouble(_goalWeightKey, state.goalWeight!);
    }
    if (state.currentWeight != null) {
      await prefs.setDouble(_currentWeightKey, state.currentWeight!);
    }
    if (state.startWeight != null) {
      await prefs.setDouble(_startWeightKey, state.startWeight!);
    }
    await prefs.setString(
      _weightLogKey,
      jsonEncode(state.weightLog.map((e) => e.toJson()).toList()),
    );
  }
}
