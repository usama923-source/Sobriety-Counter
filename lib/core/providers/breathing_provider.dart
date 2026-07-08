import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/breathing_service.dart';

/// Provider for the BreathingService (breath challenge timer + history).
final breathingServiceProvider = ChangeNotifierProvider<BreathingService>((ref) {
  final service = BreathingService();
  service.init();
  // ChangeNotifierProvider auto-disposes the notifier — no need for ref.onDispose.
  return service;
});
