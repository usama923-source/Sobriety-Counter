import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/services/quotes_service.dart';

/// Provider for the QuotesService (daily quotes, favorites).
final quotesServiceProvider = ChangeNotifierProvider<QuotesService>((ref) {
  final service = QuotesService();
  service.init();
  return service;
});

/// Provider that exposes the current quote text.
final currentQuoteProvider = Provider<String>((ref) {
  return ref.watch(quotesServiceProvider).currentQuote.text;
});

/// Provider that exposes the current quote author.
final currentQuoteAuthorProvider = Provider<String>((ref) {
  return ref.watch(quotesServiceProvider).currentQuote.author;
});

/// Provider that exposes whether the current quote is favorited.
final isCurrentFavoriteProvider = Provider<bool>((ref) {
  return ref.watch(quotesServiceProvider).isCurrentFavorite;
});

/// Provider that exposes whether the current quote is the daily quote.
final isDailyQuoteProvider = Provider<bool>((ref) {
  return ref.watch(quotesServiceProvider).isDaily;
});
