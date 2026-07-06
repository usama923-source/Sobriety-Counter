import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/data/quotes.dart';

/// Manages daily motivational quotes, favorites, and sharing.
class QuotesService extends ChangeNotifier {
  static const _favoritesKey = 'favorite_quote_indices';

  /// The quote shown at app launch (seeded by today's date so it's stable).
  Quote get dailyQuote => allQuotes[_dailyIndex];

  /// The currently displayed quote (may change when user taps "New Quote").
  Quote get currentQuote => allQuotes[_currentIndex];

  /// Indices of favorited quotes.
  Set<int> _favoriteIndices = {};
  Set<int> get favoriteIndices => Set.unmodifiable(_favoriteIndices);

  final int _dailyIndex;
  int _currentIndex;

  QuotesService()
      : _dailyIndex = _seedFromDate(),
        _currentIndex = _seedFromDate();

  static int _seedFromDate() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return Random(seed).nextInt(allQuotes.length);
  }

  // ── Initialization ──────────────────────────────────────────────────

  /// Load saved favorites from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoritesKey);
    if (raw != null) {
      _favoriteIndices = raw.map(int.parse).toSet();
    }
    notifyListeners();
  }

  // ── Quote Navigation ───────────────────────────────────────────────

  /// Pick a random quote different from the current one.
  void nextQuote() {
    if (allQuotes.length <= 1) return;
    int newIndex;
    do {
      newIndex = Random().nextInt(allQuotes.length);
    } while (newIndex == _currentIndex);
    _currentIndex = newIndex;
    notifyListeners();
  }

  /// Reset to today's daily quote.
  void resetToDaily() {
    _currentIndex = _dailyIndex;
    notifyListeners();
  }

  // ── Favorites ──────────────────────────────────────────────────────

  bool isFavorite(int index) => _favoriteIndices.contains(index);
  bool get isCurrentFavorite => _favoriteIndices.contains(_currentIndex);

  Future<void> toggleFavorite() async {
    if (_favoriteIndices.contains(_currentIndex)) {
      _favoriteIndices.remove(_currentIndex);
    } else {
      _favoriteIndices.add(_currentIndex);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      _favoriteIndices.map((i) => i.toString()).toList(),
    );
  }

  /// Whether the current quote is today's daily quote.
  bool get isDaily => _currentIndex == _dailyIndex;

  /// Share text for the current quote.
  String get shareText =>
      '"${currentQuote.text}" — ${currentQuote.author}';
}
