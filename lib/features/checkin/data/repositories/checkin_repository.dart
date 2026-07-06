import 'package:quit_drinking/core/storage/local_storage.dart';
import 'package:quit_drinking/core/utils/result.dart';

/// Repository for daily check-in data persistence.
class CheckInRepository {
  final LocalStorage _storage;
  static const _storeKey = 'checkin_history';

  CheckInRepository({required LocalStorage storage}) : _storage = storage;

  /// Load the serialized check-in history string.
  /// Format: "2026-07-01:1,2026-06-30:1,2026-06-29:0"
  Future<Result<String?>> loadHistory() => _storage.getString(_storeKey);

  /// Save the serialized check-in history string.
  Future<Result<void>> saveHistory(String serialized) =>
      _storage.setString(_storeKey, serialized);
}
