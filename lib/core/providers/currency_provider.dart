import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/currency_service.dart';

/// Provider for the CurrencyService (selected currency + display symbol).
final currencyServiceProvider = ChangeNotifierProvider<CurrencyService>((ref) {
  final service = CurrencyService();
  service.init();
  return service;
});
