import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages a list of personal reasons for staying sober.
/// Persisted in SharedPreferences.
class ReasonsService extends ChangeNotifier {
  static const _reasonsKey = 'quit_reasons';

  List<String> _reasons = [];
  List<String> get reasons => List.unmodifiable(_reasons);
  bool get isEmpty => _reasons.isEmpty;
  int get length => _reasons.length;

  // ── Initialization ──────────────────────────────────────────────────

  /// Load reasons from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _reasons = prefs.getStringList(_reasonsKey) ?? [];
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────

  /// Add a new reason at the top of the list.
  Future<void> add(String reason) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return;
    _reasons.insert(0, trimmed);
    await _save();
    notifyListeners();
  }

  /// Update a reason at the given index.
  Future<void> update(int index, String newReason) async {
    final trimmed = newReason.trim();
    if (trimmed.isEmpty || index < 0 || index >= _reasons.length) return;
    _reasons[index] = trimmed;
    await _save();
    notifyListeners();
  }

  /// Delete a reason at the given index.
  Future<void> delete(int index) async {
    if (index < 0 || index >= _reasons.length) return;
    _reasons.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_reasonsKey, _reasons);
  }
}
