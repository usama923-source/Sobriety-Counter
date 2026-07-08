import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily check-ins: whether the user stayed alcohol-free or drank.
///
/// Stores a map of dateKey ("YYYY-MM-DD") -> bool (true = sober, false = drank)
/// in SharedPreferences. Computes streaks, success percentage, and monthly data.
class CheckInService extends ChangeNotifier {
  static const _storeKey = 'checkin_history';

  /// dateKey -> true if stayed sober, false if drank
  final Map<String, bool> _history = {};

  bool _initialized = false;
  final bool _disposed = false;

  // ── Getters ────────────────────────────────────────────────────────

  bool get initialized => _initialized;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Whether today already has a check-in recorded.
  bool get todayCheckedIn => _history.containsKey(_todayKey);

  /// Whether today's check-in was successful (sober). Only valid if [todayCheckedIn].
  bool get todaySuccessful => _history[_todayKey] ?? false;

  /// Total number of check-ins recorded.
  int get totalCheckins => _history.length;

  /// Number of successful (sober) days recorded.
  int get successfulDays =>
      _history.values.where((v) => v).length;

  /// Number of unsuccessful (drank) days.
  int get drankDays =>
      _history.values.where((v) => !v).length;

  /// Overall success percentage (0–100).
  int get successPercentage {
    if (_history.isEmpty) return 100;
    return ((successfulDays / _history.length) * 100).round();
  }

  /// Current streak of consecutive successful days (counting backward from today).
  int get currentStreak {
    final sortedDates = _history.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;

    // Start from the most recent date and count consecutive successful days
    int streak = 0;
    for (int i = sortedDates.length - 1; i >= 0; i--) {
      final key = sortedDates[i];
      if (!_history[key]!) break; // broke the streak
      // Check that dates are consecutive (or today)
      if (i > 0) {
        final prevDate = _parseDateKey(sortedDates[i - 1]);
        final currDate = _parseDateKey(sortedDates[i]);
        final diff = currDate.difference(prevDate).inDays;
        if (diff > 1) break; // gap in dates
      }
      streak++;
    }

    // If the most recent successful day is more than 1 day ago, streak is 0
    if (streak > 0) {
      final lastDate = _parseDateKey(sortedDates.last);
      final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (todayStart.difference(lastDate).inDays > 1) streak = 0;
    }

    return streak;
  }

  /// Longest streak of consecutive successful days ever recorded.
  int get longestStreak {
    final sortedDates = _history.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;

    int maxStreak = 0;
    int currentRun = 0;
    DateTime? prevDate;

    for (final key in sortedDates) {
      final date = _parseDateKey(key);
      if (!_history[key]!) {
        // Drank day resets the streak
        currentRun = 0;
        prevDate = null;
        continue;
      }
      // Check consecutive
      if (prevDate != null) {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else {
          currentRun = 1;
        }
      } else {
        currentRun = 1;
      }
      prevDate = date;
      if (currentRun > maxStreak) maxStreak = currentRun;
    }

    return maxStreak;
  }

  // ── Data Access ────────────────────────────────────────────────────

  /// Check if a specific date has a check-in.
  bool hasCheckIn(String dateKey) => _history.containsKey(dateKey);

  /// Get the status for a specific date. null means no check-in.
  bool? getStatus(String dateKey) =>
      _history.containsKey(dateKey) ? _history[dateKey] : null;

  /// Get all check-in keys for a given month.
  /// e.g. getAllForMonth(2026, 7) for July 2026
  Map<String, bool> getAllForMonth(int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final result = <String, bool>{};
    for (final entry in _history.entries) {
      if (entry.key.startsWith(prefix)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Get all check-in keys for the last N days.
  Map<String, bool> getLastDays(int days) {
    final now = DateTime.now();
    final result = <String, bool>{};
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = _formatDateKey(date);
      if (_history.containsKey(key)) {
        result[key] = _history[key]!;
      }
    }
    return result;
  }

  // ── Actions ────────────────────────────────────────────────────────

  /// Record today's check-in. If already checked in, does nothing.
  /// [sober] = true if stayed alcohol-free, false if drank.
  Future<void> checkIn(bool sober) async {
    if (todayCheckedIn) return; // Only one check-in per day

    _history[_todayKey] = sober;
    await _save();
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────────────

  /// Load history from SharedPreferences.
  Future<void> init() async {
    if (_initialized || _disposed) return;
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    final raw = prefs.getString(_storeKey);
    if (raw != null && raw.isNotEmpty) {
      final parts = raw.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final sep = trimmed.indexOf(':');
        if (sep > 0 && sep < trimmed.length - 1) {
          final key = trimmed.substring(0, sep);
          final val = trimmed.substring(sep + 1);
          if (val == '1') {
            _history[key] = true;
          } else if (val == '0') {
            _history[key] = false;
          }
        }
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _history.entries
        .map((e) => '${e.key}:${e.value ? '1' : '0'}')
        .join(',');
    await prefs.setString(_storeKey, serialized);
  }

  // ── Helpers ────────────────────────────────────────────────────────

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
