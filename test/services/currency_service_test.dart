import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/constants/currencies.dart';
import 'package:quit_drinking/core/providers/currency_provider.dart';
import 'package:quit_drinking/services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurrencyService newService() {
    final service = CurrencyService();
    addTearDown(service.dispose);
    return service;
  }

  group('Currencies — shared symbol table', () {
    test('maps every supported code to its symbol', () {
      expect(Currencies.symbol('USD'), r'$');
      expect(Currencies.symbol('EUR'), '€');
      expect(Currencies.symbol('GBP'), '£');
      expect(Currencies.symbol('CAD'), r'CA$');
      expect(Currencies.symbol('AUD'), r'A$');
    });

    test('keeps the same five currencies, each with a flag', () {
      expect(Currencies.supported, ['USD', 'EUR', 'GBP', 'CAD', 'AUD']);
      for (final code in Currencies.supported) {
        expect(Currencies.flag(code), isNotEmpty);
      }
    });

    test('falls back to USD for unknown, null or oddly cased codes', () {
      expect(Currencies.normalize('XYZ'), 'USD');
      expect(Currencies.normalize(null), 'USD');
      expect(Currencies.normalize('eur'), 'EUR');
    });
  });

  group('CurrencyService', () {
    test('defaults to USD when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final service = newService();

      await service.init();

      expect(service.code, 'USD');
      expect(service.symbol, r'$');
    });

    test('restores the stored currency', () async {
      SharedPreferences.setMockInitialValues({'currency': 'GBP'});
      final service = newService();

      await service.init();

      expect(service.code, 'GBP');
      expect(service.symbol, '£');
    });

    test('notifies listeners as soon as the currency changes', () async {
      SharedPreferences.setMockInitialValues({});
      final service = newService();
      await service.init();

      var notifications = 0;
      service.addListener(() => notifications++);

      await service.setCurrency('EUR');

      expect(service.code, 'EUR');
      expect(service.symbol, '€');
      expect(notifications, 1);
    });

    test('does not notify when the same currency is re-selected', () async {
      SharedPreferences.setMockInitialValues({'currency': 'EUR'});
      final service = newService();
      await service.init();

      var notifications = 0;
      service.addListener(() => notifications++);

      await service.setCurrency('EUR');

      expect(notifications, 0);
    });

    test('persists the selection for the next launch', () async {
      SharedPreferences.setMockInitialValues({});
      final first = newService();
      await first.init();
      await first.setCurrency('CAD');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('currency'), 'CAD');

      // Fresh service — this is what a restart looks like.
      final second = newService();
      await second.init();

      expect(second.code, 'CAD');
      expect(second.symbol, r'CA$');
    });

    test('falls back to USD for an unknown stored code', () async {
      SharedPreferences.setMockInitialValues({'currency': 'XYZ'});
      final service = newService();

      await service.init();

      expect(service.code, 'USD');
    });

    test('falls back to USD for an oddly typed stored value', () async {
      SharedPreferences.setMockInitialValues({'currency': 42});
      final service = newService();

      // getString() would throw here; the read must not fail the app.
      await service.init();

      expect(service.code, 'USD');
    });

    test('the provider exposes the selection to the UI', () async {
      SharedPreferences.setMockInitialValues({'currency': 'EUR'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(currencyServiceProvider);
      await service.ensureInitialized();
      expect(container.read(currencyServiceProvider).code, 'EUR');

      await service.setCurrency('AUD');

      expect(container.read(currencyServiceProvider).code, 'AUD');
      expect(container.read(currencyServiceProvider).symbol, r'A$');
    });
  });
}
