import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/sobriety_service.dart';

/// Provider for the SobrietyService (live counter, quit date, milestones).
final sobrietyServiceProvider = ChangeNotifierProvider<SobrietyService>((ref) {
  final service = SobrietyService();
  service.init();
  // ChangeNotifierProvider auto-disposes the notifier — no need for ref.onDispose.
  return service;
});

/// Provider that exposes the total days sober.
final totalDaysProvider = Provider<int>((ref) {
  return ref.watch(sobrietyServiceProvider).totalDays;
});

/// Provider that exposes whether a quit date is set.
final hasQuitDateProvider = Provider<bool>((ref) {
  return ref.watch(sobrietyServiceProvider).hasQuitDate;
});
