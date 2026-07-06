import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/core/utils/result.dart';

/// Abstract local storage interface. Provides a clean API over SharedPreferences.
///
/// Using this abstraction allows:
/// - Swapping implementations (e.g., for tests or migrating to a different storage)
/// - Providing mock storage in unit tests without Flutter dependencies
abstract class LocalStorage {
  /// Initialize the storage backend.
  Future<void> init();

  // ── String ──────────────────────────────────────────────────────────

  Future<Result<String?>> getString(String key);
  Future<Result<void>> setString(String key, String value);
  Future<Result<void>> remove(String key);

  // ── Int ─────────────────────────────────────────────────────────────

  Future<Result<int?>> getInt(String key);
  Future<Result<void>> setInt(String key, int value);

  // ── Double ──────────────────────────────────────────────────────────

  Future<Result<double?>> getDouble(String key);
  Future<Result<void>> setDouble(String key, double value);

  // ── Bool ────────────────────────────────────────────────────────────

  Future<Result<bool?>> getBool(String key);
  Future<Result<void>> setBool(String key, bool value);

  // ── String List ─────────────────────────────────────────────────────

  Future<Result<List<String>?>> getStringList(String key);
  Future<Result<void>> setStringList(String key, List<String> value);

  // ── Bulk ────────────────────────────────────────────────────────────

  Future<Result<void>> clear();
}

/// SharedPreferences implementation of [LocalStorage].
///
/// Wraps every call in a try-catch and returns [Result] to propagate errors
/// explicitly instead of relying on platform exceptions.
class SharedPrefsStorage implements LocalStorage {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw StateError('LocalStorage not initialized. Call init() first.');
    return _prefs!;
  }

  @override
  Future<Result<String?>> getString(String key) async {
    try {
      return Success(_p.getString(key));
    } catch (e) {
      return Failure('Failed to read string for key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> setString(String key, String value) async {
    try {
      await _p.setString(key, value);
      return Success(null);
    } catch (e) {
      return Failure('Failed to write string for key: $key', exception: e);
    }
  }

  @override
  Future<Result<int?>> getInt(String key) async {
    try {
      return Success(_p.getInt(key));
    } catch (e) {
      return Failure('Failed to read int for key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> setInt(String key, int value) async {
    try {
      await _p.setInt(key, value);
      return Success(null);
    } catch (e) {
      return Failure('Failed to write int for key: $key', exception: e);
    }
  }

  @override
  Future<Result<double?>> getDouble(String key) async {
    try {
      return Success(_p.getDouble(key));
    } catch (e) {
      return Failure('Failed to read double for key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> setDouble(String key, double value) async {
    try {
      await _p.setDouble(key, value);
      return Success(null);
    } catch (e) {
      return Failure('Failed to write double for key: $key', exception: e);
    }
  }

  @override
  Future<Result<bool?>> getBool(String key) async {
    try {
      return Success(_p.getBool(key));
    } catch (e) {
      return Failure('Failed to read bool for key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> setBool(String key, bool value) async {
    try {
      await _p.setBool(key, value);
      return Success(null);
    } catch (e) {
      return Failure('Failed to write bool for key: $key', exception: e);
    }
  }

  @override
  Future<Result<List<String>?>> getStringList(String key) async {
    try {
      return Success(_p.getStringList(key));
    } catch (e) {
      return Failure('Failed to read string list for key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> setStringList(String key, List<String> value) async {
    try {
      await _p.setStringList(key, value);
      return Success(null);
    } catch (e) {
      return Failure('Failed to write string list for key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> remove(String key) async {
    try {
      await _p.remove(key);
      return Success(null);
    } catch (e) {
      return Failure('Failed to remove key: $key', exception: e);
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _p.clear();
      return Success(null);
    } catch (e) {
      return Failure('Failed to clear storage', exception: e);
    }
  }
}
