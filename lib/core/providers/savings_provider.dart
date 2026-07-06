import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/savings_service.dart';

/// Provider for the SavingsService (money saved calculator).
final savingsServiceProvider = ChangeNotifierProvider<SavingsService>((ref) {
  final service = SavingsService();
  service.init();
  return service;
});
