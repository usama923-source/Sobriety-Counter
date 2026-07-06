import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/checkin_service.dart';

/// Provider for the CheckInService (daily check-in, streaks, history).
final checkinServiceProvider = ChangeNotifierProvider<CheckInService>((ref) {
  final service = CheckInService();
  service.init();
  return service;
});
