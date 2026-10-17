import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'sobriety_start_date';

  /// Midnight — the value every write path stores.
  final quitDate = DateTime(2026, 10, 1);

  SobrietyService newService() {
    final service = SobrietyService();
    addTearDown(service.dispose);
    return service;
  }

  int daysSince(DateTime date) =>
      DateTime.now().difference(DateTime(date.year, date.month, date.day)).inDays;

  group('SobrietyService.init — restoring the stored quit date', () {
    test('restores a date stored as int milliseconds since epoch', () async {
      SharedPreferences.setMockInitialValues(
        {key: quitDate.millisecondsSinceEpoch},
      );
      final service = newService();

      await service.init();

      expect(service.isInitialized, isTrue);
      expect(service.hasQuitDate, isTrue);
      expect(service.quitDate, quitDate);
      expect(service.totalDays, daysSince(quitDate));
    });

    test('restores a date stored as an ISO-8601 String by older builds',
        () async {
      SharedPreferences.setMockInitialValues(
        {key: '2026-10-01T13:45:00.000'},
      );
      final service = newService();

      await service.init();

      // Normalized to midnight, exactly like setQuitDate().
      expect(service.quitDate, quitDate);
      expect(service.totalDays, daysSince(quitDate));
    });

    test('normalizes a stored timestamp that still carries a time of day',
        () async {
      SharedPreferences.setMockInitialValues(
        {key: DateTime(2026, 10, 1, 23, 59).millisecondsSinceEpoch},
      );
      final service = newService();

      await service.init();

      expect(service.quitDate, quitDate);
    });

    test('reports no quit date when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final service = newService();

      await service.init();

      expect(service.isInitialized, isTrue);
      expect(service.hasQuitDate, isFalse);
      expect(service.quitDate, isNull);
      expect(service.totalDays, 0);
    });

    test('ignores an unparsable value instead of throwing', () async {
      SharedPreferences.setMockInitialValues({key: 'not-a-date'});
      final service = newService();

      await service.init();

      expect(service.hasQuitDate, isFalse);
    });

    test('ignores a value with an unexpected type instead of throwing',
        () async {
      SharedPreferences.setMockInitialValues({key: true});
      final service = newService();

      // getString() would throw here; the stored date must simply be skipped.
      await service.init();

      expect(service.isInitialized, isTrue);
      expect(service.hasQuitDate, isFalse);
    });

    test('shows the restored date', () async {
      SharedPreferences.setMockInitialValues(
        {key: quitDate.millisecondsSinceEpoch},
      );
      final service = newService();

      await service.init();

      expect(service.startDateFormatted, 'Oct 1, 2026');
    });
  });

  group('SobrietyService — persistence across a restart', () {
    test('a saved quit date survives a restart of the service', () async {
      SharedPreferences.setMockInitialValues({});
      final first = newService();

      await first.setQuitDate(DateTime(2026, 9, 15));

      final second = newService();
      await second.init();

      expect(second.isInitialized, isTrue);
      expect(second.quitDate, DateTime(2026, 9, 15));
      expect(second.totalDays, daysSince(DateTime(2026, 9, 15)));
    });

    test('an ISO-8601 value written by an older build survives a restart',
        () async {
      // Simulates the pre-fix writer that lived in the daily check-in card.
      SharedPreferences.setMockInitialValues(
        {key: DateTime(2026, 8, 1, 9, 30).toIso8601String()},
      );

      final service = newService();
      await service.init();

      expect(service.hasQuitDate, isTrue);
      expect(service.quitDate, DateTime(2026, 8, 1));
    });

    test('resetSobriety persists an int the next launch can read', () async {
      SharedPreferences.setMockInitialValues(
        {key: '2026-01-01T00:00:00.000'},
      );
      final first = newService();
      await first.init();
      expect(first.totalDays, greaterThan(0));

      await first.resetSobriety();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(key), isA<int>());

      final second = newService();
      await second.init();

      expect(second.hasQuitDate, isTrue);
      expect(second.totalDays, 0); // the counter restarted
    });

    test('clearQuitDate removes the stored date', () async {
      SharedPreferences.setMockInitialValues(
        {key: quitDate.millisecondsSinceEpoch},
      );
      final service = newService();
      await service.init();

      await service.clearQuitDate();

      expect(service.hasQuitDate, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(key), isNull);
    });
  });

  group('sobriety providers', () {
    test('report the stored date once initialization has completed', () async {
      SharedPreferences.setMockInitialValues(
        {key: quitDate.millisecondsSinceEpoch},
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Reading the provider starts the load; the UI-visible providers below
      // must not answer before that load finishes.
      final service = container.read(sobrietyServiceProvider);
      await service.initialized;

      expect(service.isInitialized, isTrue);
      expect(container.read(hasQuitDateProvider), isTrue);
      expect(container.read(totalDaysProvider), daysSince(quitDate));
    });

    test('report no quit date when none is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(sobrietyServiceProvider);
      await service.initialized;

      expect(container.read(hasQuitDateProvider), isFalse);
      expect(container.read(totalDaysProvider), 0);
    });
  });
}
