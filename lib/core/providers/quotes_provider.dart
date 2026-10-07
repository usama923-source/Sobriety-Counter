import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/quotes_service.dart';

/// Provider for the QuotesService (daily quotes, favorites).
final quotesServiceProvider = ChangeNotifierProvider<QuotesService>((ref) {
  final service = QuotesService();
  service.init();
  return service;
});
