/// API configuration for the AI Friend chat feature.
///
/// ═══════════════════════════════════════════════════════════════════════════
///  IMPORTANT: This is an EXAMPLE file. To use the AI chat feature:
///
///  1. Copy this file:  `api_config.example.dart` → `api_config.dart`
///  2. Replace the placeholder API key below with your actual key
///  3. Get a free Groq API key at: https://console.groq.com/keys
///  4. Never commit `api_config.dart` to version control
///
///  The app will use simulated responses (no API call) when the key
///  is set to the placeholder value below.
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
  static const String apiKey = 'YOUR_API_KEY_HERE';

  /// The AI model to use.
  /// Available models: https://console.groq.com/docs/models
  static const String model = 'llama-3.1-8b-instant';

  /// Display name for the AI companion
  static const String aiName = 'AI Friend';
}
