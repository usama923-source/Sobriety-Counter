import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/models/milestone.dart';

/// Manages the sobriety quit date, calculates duration, and provides
/// a live counter that updates every second.
class SobrietyService extends ChangeNotifier {
  static const _quitDateKey = 'sobriety_start_date';

  DateTime? _quitDate;
  Timer? _timer;
  bool _disposed = false;

  /// Completed by the first [init] once the stored date has been read.
  final Completer<void> _initialized = Completer<void>();

  /// Whether the stored quit date has finished loading from storage.
  ///
  /// The UI waits for this before concluding that no quit date exists, so a
  /// saved date is never briefly reported as missing on launch.
  bool get isInitialized => _initialized.isCompleted;

  /// Completes when [init] has finished its first load.
  Future<void> get initialized => _initialized.future;

  /// The stored quit date, or null if not set.
  DateTime? get quitDate => _quitDate;

  /// Whether the user has set a quit date.
  bool get hasQuitDate => _quitDate != null;

  /// Total duration since the quit date.
  Duration get duration {
    if (_quitDate == null) return Duration.zero;
    return DateTime.now().difference(_quitDate!);
  }

  /// Total full days since quit date.
  int get totalDays => duration.inDays;

  /// Hours within the current day (0–23).
  int get hours => duration.inHours.remainder(24);

  /// Minutes within the current hour (0–59).
  int get minutes => duration.inMinutes.remainder(60);

  /// Seconds within the current minute (0–59).
  int get seconds => duration.inSeconds.remainder(60);

  /// Formatted start date string, e.g. "May 14, 2026".
  String get startDateFormatted {
    if (_quitDate == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[_quitDate!.month - 1]} ${_quitDate!.day}, ${_quitDate!.year}';
  }

  /// The next milestone the user is working towards, or null if all done.
  Milestone? get nextMilestone {
    if (_quitDate == null) return null;
    for (final m in Milestone.all) {
      if (!m.isCompleted(totalDays)) return m;
    }
    return null;
  }

  /// All milestones, annotated with completion status.
  List<({Milestone milestone, bool completed})> get milestonesWithStatus {
    return Milestone.all.map((m) => (milestone: m, completed: m.isCompleted(totalDays))).toList();
  }

  /// The number of days until the next milestone.
  int? get daysUntilNextMilestone {
    final next = nextMilestone;
    if (next == null) return null;
    return next.dayThreshold - totalDays;
  }

  // ── Initialization ────────────────────────────────────────────────────

  /// Load the quit date from [SharedPreferences] and start the timer.
  ///
  /// The stored value is inspected by its runtime type, so a date saved as
  /// int milliseconds since epoch ([setQuitDate], [resetSobriety]) and one
  /// saved as an ISO-8601 string (older builds) are both restored, and a
  /// value of the "wrong" type can no longer make the read throw.
  ///
  /// The restored date is normalized to midnight, matching [setQuitDate].
  Future<void> init() async {
    if (_disposed) return;

    DateTime? stored;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      stored = _readStoredQuitDate(prefs);
    } catch (e, stackTrace) {
      // Never swallow a storage failure silently, and never let it look
      // like "no quit date" without leaving a trace.
      debugPrint('[Sobriety] Failed to load the quit date: $e\n$stackTrace');
    }

    if (_disposed) return;

    // Only replace what we already hold when storage actually returned a
    // date — a read failure must not wipe a date the user already has.
    if (stored != null) {
      _quitDate = DateTime(stored.year, stored.month, stored.day);
    }

    if (!_initialized.isCompleted) _initialized.complete();

    _startTimer();
    notifyListeners();
  }

  /// Reads the stored quit date from either supported storage format.
  ///
  /// [SharedPreferences.get] hands back the raw value without casting, so a
  /// key that holds an int cannot make the read throw (which is what
  /// `getString` does when the stored value is not a string).
  DateTime? _readStoredQuitDate(SharedPreferences prefs) {
    final Object? raw = prefs.get(_quitDateKey);
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// Set a new quit date, persist it, and restart the counter.
  Future<void> setQuitDate(DateTime date) async {
    _quitDate = DateTime(date.year, date.month, date.day); // normalize to midnight
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quitDateKey, _quitDate!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Clear the quit date.
  Future<void> clearQuitDate() async {
    _quitDate = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quitDateKey);
    notifyListeners();
  }

  /// Reset sobriety — sets the start date to right now and restarts the timer.
  /// Used when the user reports a relapse.
  Future<void> resetSobriety() async {
    _quitDate = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quitDateKey, _quitDate!.millisecondsSinceEpoch);
    notifyListeners();
  }

  // ── Timer ─────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (_quitDate != null) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
