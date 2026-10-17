/// Supported currencies with their symbols and flags.
///
/// Single source of truth for the currency pickers (onboarding and Settings)
/// and for money formatting, so the code stored in SharedPreferences under
/// "currency" always resolves to the same symbol everywhere.
class Currencies {
  Currencies._();

  /// The codes the app offers, in picker order.
  static const List<String> supported = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];

  /// Used when nothing supported is stored.
  static const String fallback = 'USD';

  /// Whether [code] is one of [supported].
  static bool isSupported(String? code) =>
      code != null && supported.contains(code);

  /// [code] (case-insensitive) when it is supported, otherwise [fallback].
  static String normalize(String? code) {
    final upper = code?.toUpperCase();
    return isSupported(upper) ? upper! : fallback;
  }

  /// Display symbol for [code].
  static String symbol(String code) {
    switch (normalize(code)) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'A\$';
      case 'USD':
      default:
        return '\$';
    }
  }

  /// Flag emoji for [code], used by the onboarding picker.
  static String flag(String code) {
    switch (normalize(code)) {
      case 'EUR':
        return '\u{1F1EA}\u{1F1FA}';
      case 'GBP':
        return '\u{1F1EC}\u{1F1E7}';
      case 'CAD':
        return '\u{1F1E8}\u{1F1E6}';
      case 'AUD':
        return '\u{1F1E6}\u{1F1FA}';
      case 'USD':
      default:
        return '\u{1F1FA}\u{1F1F8}';
    }
  }
}
