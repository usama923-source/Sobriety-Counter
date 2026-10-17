/// Chat configuration for the AI Friend feature.
///
/// No API credentials live in the app any more: replies are generated through
/// Firebase AI Logic (Google's Gemini) and protected by Firebase App Check.
/// Only non-sensitive presentation and usage-limit constants remain here.
library;

class ApiConfig {
  ApiConfig._();

  /// Display name for the AI companion
  static const String aiName = 'AI Friend';

  // ── Temporary client-side chat safeguards ─────────────────────────────
  // These limits keep usage (and cost) in check until a server-side proxy
  // enforces them. They live here so every number sits in one place.

  /// Maximum user messages per device per calendar day.
  static const int dailyMessageLimit = 25;

  /// Maximum characters allowed in a single chat message.
  static const int maxMessageLength = 500;

  /// How many of the most recent messages are sent as history.
  static const int historyMessageLimit = 10;

  /// Maximum tokens requested from the model per reply.
  static const int maxResponseTokens = 300;
}
