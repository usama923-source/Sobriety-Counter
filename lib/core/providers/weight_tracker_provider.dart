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
  final List<WeightEntry> weightLog;
  final bool isLoading;

  const WeightTrackerState({
    this.goalWeight,
    this.currentWeight,
    this.weightLog = const [],
    this.isLoading = true,
  });

  /// First logged weight, falling back to the current weight.
  double? get firstLoggedWeight =>
      weightLog.isNotEmpty ? weightLog.first.weight : currentWeight;

  /// Total weight lost since the first logged entry.
  double? get weightLost {
    if (firstLoggedWeight == null || currentWeight == null) return null;
    return firstLoggedWeight! - currentWeight!;
  }

  /// Progress toward the goal weight, clamped to 0..1.
  double? get progress {
    if (goalWeight == null || currentWeight == null) return null;
    final start = firstLoggedWeight ?? currentWeight!;
    if (start <= goalWeight!) return 1.0; // Already at or past goal
    final total = start - goalWeight!;
    final soFar = start - currentWeight!;
    return (soFar / total).clamp(0.0, 1.0);
  }

  WeightTrackerState copyWith({
    double? goalWeight,
    double? currentWeight,
    List<WeightEntry>? weightLog,
    bool? isLoading,
  }) {
    return WeightTrackerState(
      goalWeight: goalWeight ?? this.goalWeight,
      currentWeight: currentWeight ?? this.currentWeight,
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
      weightLog: log,
      isLoading: false,
    );
  }

  /// Set and persist the goal weight.
  Future<void> setGoalWeight(double weight) async {
    state = state.copyWith(goalWeight: weight);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalWeightKey, weight);
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
      weightLog: convertedLog,
    );

    final prefs = await SharedPreferences.getInstance();
    if (state.goalWeight != null) {
      await prefs.setDouble(_goalWeightKey, state.goalWeight!);
    }
    if (state.currentWeight != null) {
      await prefs.setDouble(_currentWeightKey, state.currentWeight!);
    }
    await prefs.setString(
      _weightLogKey,
      jsonEncode(state.weightLog.map((e) => e.toJson()).toList()),
    );
  }
}
