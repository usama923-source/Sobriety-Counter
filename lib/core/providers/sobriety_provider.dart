import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:quit_drinking/models/milestone.dart';

/// Provider for the SobrietyService (live counter, quit date, milestones).
final sobrietyServiceProvider = ChangeNotifierProvider<SobrietyService>((ref) {
  final service = SobrietyService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider that exposes the total days sober.
final totalDaysProvider = Provider<int>((ref) {
  return ref.watch(sobrietyServiceProvider).totalDays;
});

/// Provider that exposes the quit date formatted string.
final startDateProvider = Provider<String>((ref) {
  return ref.watch(sobrietyServiceProvider).startDateFormatted;
});

/// Provider that exposes the next milestone, or null if all completed.
final nextMilestoneProvider = Provider<Milestone?>((ref) {
  return ref.watch(sobrietyServiceProvider).nextMilestone;
});

/// Provider that exposes all milestones with completion status.
final milestonesWithStatusProvider =
    Provider<List<({Milestone milestone, bool completed})>>((ref) {
  return ref.watch(sobrietyServiceProvider).milestonesWithStatus;
});

/// Provider that exposes whether a quit date is set.
final hasQuitDateProvider = Provider<bool>((ref) {
  return ref.watch(sobrietyServiceProvider).hasQuitDate;
});
