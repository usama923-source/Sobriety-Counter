import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/reasons_service.dart';

/// Provider for the ReasonsService (CRUD for personal reasons).
final reasonsServiceProvider = ChangeNotifierProvider<ReasonsService>((ref) {
  final service = ReasonsService();
  service.init();
  return service;
});

/// Provider that exposes the list of reasons.
final reasonsListProvider = Provider<List<String>>((ref) {
  return ref.watch(reasonsServiceProvider).reasons;
});

/// Provider that exposes whether the reasons list is empty.
final reasonsIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(reasonsServiceProvider).isEmpty;
});
