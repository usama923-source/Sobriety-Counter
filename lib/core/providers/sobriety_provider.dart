import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/sobriety_service.dart';

/// Provider for the SobrietyService (live counter, quit date, milestones).
final sobrietyServiceProvider = ChangeNotifierProvider<SobrietyService>((ref) {
  final service = SobrietyService();
  // Load the stored quit date as soon as this service is first needed.
  service.init();
  // ChangeNotifierProvider auto-disposes the notifier — no need for ref.onDispose.
  return service;
});

/// Completes once the stored quit date has been loaded from storage.
///
/// Consumers wait on this instead of reading [SobrietyService.hasQuitDate]
/// while initialization is still in flight, which would briefly look like
/// "the user never set a date".
final sobrietyInitProvider = FutureProvider<void>((ref) {
  return ref.watch(sobrietyServiceProvider).initialized;
});

/// Provider that exposes the total days sober.
final totalDaysProvider = Provider<int>((ref) {
  // Recomputed once storage has been read, so the first answer is never a
  // pre-initialization zero.
  ref.watch(sobrietyInitProvider);
  return ref.watch(sobrietyServiceProvider).totalDays;
});

/// Provider that exposes whether a quit date is set.
final hasQuitDateProvider = Provider<bool>((ref) {
  ref.watch(sobrietyInitProvider);
  return ref.watch(sobrietyServiceProvider).hasQuitDate;
});
