import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/core/storage/local_storage.dart';
import 'package:quit_drinking/core/utils/result.dart';
import 'package:quit_drinking/features/sobriety/data/repositories/sobriety_repository.dart';

/// An in-memory implementation of [LocalStorage] for testing.
class MockLocalStorage implements LocalStorage {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<String?>> getString(String key) async =>
      Success(_store[key] as String?);

  @override
  Future<Result<void>> setString(String key, String value) async {
    _store[key] = value;
    return Success(null);
  }

  @override
  Future<Result<int?>> getInt(String key) async =>
      Success(_store[key] as int?);

  @override
  Future<Result<void>> setInt(String key, int value) async {
    _store[key] = value;
    return Success(null);
  }

  @override
  Future<Result<double?>> getDouble(String key) async =>
      Success(_store[key] as double?);

  @override
  Future<Result<void>> setDouble(String key, double value) async {
    _store[key] = value;
    return Success(null);
  }

  @override
  Future<Result<bool?>> getBool(String key) async =>
      Success(_store[key] as bool?);

  @override
  Future<Result<void>> setBool(String key, bool value) async {
    _store[key] = value;
    return Success(null);
  }

  @override
  Future<Result<List<String>?>> getStringList(String key) async =>
      Success(_store[key] as List<String>?);

  @override
  Future<Result<void>> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return Success(null);
  }

  @override
  Future<Result<void>> remove(String key) async {
    _store.remove(key);
    return Success(null);
  }

  @override
  Future<Result<void>> clear() async {
    _store.clear();
    return Success(null);
  }
}

void main() {
  group('LocalStorage abstraction', () {
    test('MockLocalStorage implements all methods', () async {
      final storage = MockLocalStorage();
      await storage.init();
      expect(storage, isA<LocalStorage>());
    });

    test('setInt and getInt round-trip correctly', () async {
      final storage = MockLocalStorage();
      await storage.init();

      final writeResult = await storage.setInt('test_key', 42);
      expect(writeResult, isA<Success>());

      final readResult = await storage.getInt('test_key');
      expect(readResult, isA<Success>());
      expect(readResult.orThrow, 42);
    });

    test('setString and getString round-trip correctly', () async {
      final storage = MockLocalStorage();
      await storage.init();

      await storage.setString('greeting', 'hello');
      final result = await storage.getString('greeting');
      expect(result.orThrow, 'hello');
    });

    test('remove deletes a key', () async {
      final storage = MockLocalStorage();
      await storage.init();

      await storage.setString('temp', 'value');
      expect((await storage.getString('temp')).orThrow, 'value');

      await storage.remove('temp');
      expect((await storage.getString('temp')).orThrow, isNull);
    });

    test('clear removes all keys', () async {
      final storage = MockLocalStorage();
      await storage.init();

      await storage.setInt('a', 1);
      await storage.setString('b', 'two');
      await storage.clear();

      expect((await storage.getInt('a')).orThrow, isNull);
      expect((await storage.getString('b')).orThrow, isNull);
    });
  });

  group('SobrietyRepository (repository pattern)', () {
    test('loadQuitDate returns null when nothing saved', () async {
      final storage = MockLocalStorage();
      await storage.init();
      final repo = SobrietyRepository(storage: storage);

      final result = await repo.loadQuitDate();
      expect(result, isA<Success>());
      expect(result.orThrow, isNull);
    });

    test('saveQuitDate and loadQuitDate round-trip', () async {
      final storage = MockLocalStorage();
      await storage.init();
      final repo = SobrietyRepository(storage: storage);

      await repo.saveQuitDate(1719878400000); // July 2, 2024

      final result = await repo.loadQuitDate();
      expect(result.orThrow, 1719878400000);
    });

    test('clearQuitDate removes saved date', () async {
      final storage = MockLocalStorage();
      await storage.init();
      final repo = SobrietyRepository(storage: storage);

      await repo.saveQuitDate(1719878400000);
      expect((await repo.loadQuitDate()).orThrow, isNotNull);

      await repo.clearQuitDate();
      expect((await repo.loadQuitDate()).orThrow, isNull);
    });
  });
}
