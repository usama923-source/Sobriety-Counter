import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/reasons_service.dart';

/// Provider for the ReasonsService (CRUD for personal reasons).
final reasonsServiceProvider = ChangeNotifierProvider<ReasonsService>((ref) {
  final service = ReasonsService();
  service.init();
  return service;
});
