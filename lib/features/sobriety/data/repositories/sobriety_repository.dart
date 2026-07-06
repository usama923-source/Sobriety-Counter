import 'package:quit_drinking/core/storage/local_storage.dart';
import 'package:quit_drinking/core/utils/result.dart';

/// Repository for sobriety data persistence.
///
/// Demonstrates the repository pattern: encapsulates data access logic
/// and provides a clean API for the domain/service layer.
class SobrietyRepository {
  final LocalStorage _storage;

  static const _quitDateKey = 'quit_date_millis';

  SobrietyRepository({required LocalStorage storage}) : _storage = storage;

  /// Load the saved quit date from local storage.
  /// Returns milliseconds since epoch or null if not set.
  Future<Result<int?>> loadQuitDate() => _storage.getInt(_quitDateKey);

  /// Save the quit date (as milliseconds since epoch) to local storage.
  Future<Result<void>> saveQuitDate(int millis) =>
      _storage.setInt(_quitDateKey, millis);

  /// Remove the quit date from local storage.
  Future<Result<void>> clearQuitDate() => _storage.remove(_quitDateKey);
}
