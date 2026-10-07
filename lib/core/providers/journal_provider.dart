import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Container for all journal-related state and operations.
///
/// This provider owns the persisted journal entries (via SharedPreferences)
/// and exposes them to the JournalScreen. UI-only state (loading, saving,
/// text input) remains in the screen's setState.
final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  return JournalNotifier();
});

/// The state held by the journal provider.
class JournalState {
  final List<JournalEntry> entries;
  bool isLoading;

  JournalState({
    this.entries = const [],
    this.isLoading = true,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// The model for a single journal entry.
class JournalEntry {
  final String text;
  final DateTime timestamp;

  const JournalEntry({required this.text, required this.timestamp});

  factory JournalEntry.fromJson(String json) {
    // Format: \"timestamp_unix|text\"
    final parts = json.split('|');
    if (parts.length >= 2) {
      final ts = int.tryParse(parts[0]) ?? 0;
      return JournalEntry(
        text: parts.sublist(1).join('|'),
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    }
    return JournalEntry(text: json, timestamp: DateTime.now());
  }

  String toJson() => '${timestamp.millisecondsSinceEpoch}|$text';
}

/// The notifier that manages journal state and persistence.
class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier() : super(JournalState()) {
    _loadEntries();
  }

  final _storageKey = 'craving_journal_entries';

  /// Load entries from SharedPreferences and update state.
  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final List<JournalEntry> loaded = raw
        .map((s) => JournalEntry.fromJson(s))
        .toList();
    state = state.copyWith(
      entries: loaded,
      isLoading: false,
    );
  }

  /// Save a new entry. Persists to SharedPreferences.
  Future<void> addEntry(String text) async {
    final entry = JournalEntry(
      text: text,
      timestamp: DateTime.now(),
    );
    final updated = [entry, ...state.entries];
    state = state.copyWith(entries: updated);
    await _persistEntries();
  }

  /// Delete an entry at [index]. Persists to SharedPreferences.
  Future<void> deleteEntry(int index) async {
    final updated = List<JournalEntry>.from(state.entries);
    updated.removeAt(index);
    state = state.copyWith(entries: updated);
    await _persistEntries();
  }

  /// Persist entries to SharedPreferences.
  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.entries.map((e) => e.toJson()).toList(),
    );
  }
}
