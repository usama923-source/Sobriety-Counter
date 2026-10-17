import 'package:flutter/foundation.dart';
import 'package:quit_drinking/constants/currencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen currency and keeps it in sync with storage.
///
/// The selection lives here rather than in the widgets, so every screen that
/// shows money rebuilds the moment the choice changes.
class CurrencyService extends ChangeNotifier {
  static const String _key = 'currency';

  String _code = Currencies.fallback;
  Future<void>? _initialLoad;

  /// The selected currency code, always one of [Currencies.supported].
  String get code => _code;

  /// Display symbol for the selected currency.
  String get symbol => Currencies.symbol(_code);

  /// Loads the stored currency once. Safe to call repeatedly.
  Future<void> init() => _initialLoad ??= _load();

  /// Completes when the stored currency has been read.
  Future<void> ensureInitialized() => init();

  Future<void> _load() async {
    var stored = Currencies.fallback;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Read the raw value: `getString` throws when the stored value has any
      // other type, which would make an oddly stored key look like a failure
      // instead of simply falling back to the default currency.
      final Object? raw = prefs.get(_key);
      stored = Currencies.normalize(raw is String ? raw : null);
    } catch (e) {
      debugPrint('[Currency] Failed to load the saved currency: $e');
    }

    if (stored != _code) {
      _code = stored;
      notifyListeners();
    }
  }

  /// Persists [code] and notifies listeners straight away, so the UI updates
  /// without waiting on the platform channel.
  Future<void> setCurrency(String code) async {
    final next = Currencies.normalize(code);
    if (next != _code) {
      _code = next;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, next);
    } catch (e) {
      debugPrint('[Currency] Failed to save the currency: $e');
    }
  }
}
