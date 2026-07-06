import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the Breath Challenge: timer, best time, and session history.
class BreathingService extends ChangeNotifier {
  static const _bestTimeKey = 'breath_best_time_seconds';
  static const _historyKey = 'breath_history';

  Timer? _timer;
  int _elapsedSeconds = 0;
  int _bestTimeSeconds = 0;
  List<int> _history = [];
  bool _isRunning = false;

  // ── Getters ────────────────────────────────────────────────────────

  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  int get bestTimeSeconds => _bestTimeSeconds;
  List<int> get history => List.unmodifiable(_history);
  bool get hasBestTime => _bestTimeSeconds > 0;
  bool get isNewBest =>
      _isRunning && _elapsedSeconds > _bestTimeSeconds && _bestTimeSeconds > 0;

  String get elapsedDisplay => _formatSeconds(_elapsedSeconds);
  String get bestTimeDisplay => _formatSeconds(_bestTimeSeconds);

  String _formatSeconds(int total) {
    final min = total ~/ 60;
    final sec = total % 60;
    final hours = min ~/ 60;
    if (hours > 0) {
      return '${hours}h ${min % 60}m ${sec}s';
    }
    return '${min}m ${sec.toString().padLeft(2, '0')}s';
  }

  // ── Timer Control ─────────────────────────────────────────────────

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void stop() {
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;

    // Check for new best time
    if (_elapsedSeconds > _bestTimeSeconds) {
      _bestTimeSeconds = _elapsedSeconds;
      _saveBestTime();
    }

    // Save to history
    _history.insert(0, _elapsedSeconds);
    if (_history.length > 50) _history = _history.sublist(0, 50);
    _saveHistory();

    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _bestTimeSeconds = prefs.getInt(_bestTimeKey) ?? 0;
    final raw = prefs.getStringList(_historyKey);
    if (raw != null) {
      _history = raw.map((s) => int.tryParse(s) ?? 0).where((n) => n > 0).toList();
    }
    notifyListeners();
  }

  Future<void> _saveBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestTimeKey, _bestTimeSeconds);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      _history.map((n) => n.toString()).toList(),
    );
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
