/// API configuration for the AI Friend chat feature.
///
/// ═══════════════════════════════════════════════════════════════════════════
///  IMPORTANT: This file contains sensitive API credentials and is excluded
///  from version control via .gitignore.
///
///  To set up your own API key:
///  1. Copy `api_config.example.dart` → `api_config.dart`
///  2. Replace the placeholder values with your actual API key
///  3. Never commit `api_config.dart` to version control
/// ═══════════════════════════════════════════════════════════════════════════
library;

class ApiConfig {
  ApiConfig._();

  /// The API endpoint URL for your AI chat service.
  /// Default: Groq API endpoint for Llama/Mixtral models
  static const String apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Your API key / authentication header value.
  ///
  /// Get a free Groq API key at: https://console.groq.com/keys
  /// Format: "Bearer gsk_..."
  static const String apiKey =
      '<REDACTED_GROQ_KEY>';

  /// The AI model to use.
  /// Available models: https://console.groq.com/docs/models
  /// (llama3-8b-8192 was deprecated 2025-08-30)
  static const String model = 'llama-3.1-8b-instant';

  /// Display name for the AI companion
  static const String aiName = 'AI Friend';
}
