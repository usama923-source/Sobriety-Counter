import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages a list of personal reasons for staying sober.
///
/// Persisted in SharedPreferences under the key "my_reasons" as a
/// JSON-encoded list of strings. This is the single source of truth used by
/// both the home card and the My Reasons screen.
class ReasonsService extends ChangeNotifier {
  /// Standard storage key — must match the key used by every other consumer.
  static const String storageKey = 'my_reasons';

  /// Legacy key from an older version that stored a plain string list here.
  static const String _legacyKey = 'quit_reasons';

  List<String> _reasons = [];
  bool _initialized = false;

  List<String> get reasons => List.unmodifiable(_reasons);
  bool get isEmpty => _reasons.isEmpty;
  int get length => _reasons.length;

  /// Whether [init] has completed at least once.
  bool get initialized => _initialized;

  // ── Initialization ──────────────────────────────────────────────────

  /// Load reasons from SharedPreferences, migrating any legacy formats.
  ///
  /// [storageKey] may hold either the canonical JSON-encoded list of strings
  /// or the plain string list written by onboarding (`setStringList`). Both
  /// are accepted and then rewritten as one canonical JSON string.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // `get` returns the raw value without casting, so a key holding a list
      // cannot make the read throw (which `getString` would).
      final Object? raw = prefs.get(storageKey);
      if (raw is String) {
        if (raw.isNotEmpty) _reasons = _decode(raw);
      } else if (raw is List) {
        _reasons = raw.whereType<String>().toList();
      } else if (raw == null) {
        // Migrate the even older "quit_reasons" storage, which may be either
        // a plain string list or a JSON-encoded list.
        final Object? legacy = prefs.get(_legacyKey);
        if (legacy is List) {
          _reasons = legacy.whereType<String>().toList();
        } else if (legacy is String && legacy.isNotEmpty) {
          _reasons = _decode(legacy);
        }
      }

      // Rewrite in one canonical format whenever the stored value was not
      // already that format, and drop the obsolete key.
      if (raw is List || prefs.containsKey(_legacyKey)) {
        await _save();
        await prefs.remove(_legacyKey);
      }
    } catch (e, stackTrace) {
      debugPrint('[Reasons] Failed to load reasons: $e\n$stackTrace');
    }

    _initialized = true;
    notifyListeners();
  }

  List<String> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {
      // Corrupt data — fall through to an empty list.
    }
    return [];
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
    await prefs.setString(storageKey, jsonEncode(_reasons));
  }
}
