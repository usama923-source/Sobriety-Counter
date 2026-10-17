import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/config/api_config.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';

// ── Chat Message Model ─────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['ts'] as int?) ?? 0,
        ),
      );
}

// ── Screen ──────────────────────────────────────────────────────────────

/// AI Friend Chat screen — a supportive AI companion to help users
/// through their sobriety journey.
///
/// Replies come from Firebase AI Logic (Google's Gemini), protected by
/// Firebase App Check. No API key ships in the app.
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with WidgetsBindingObserver {
  // ── State ─────────────────────────────────────────────────────────────

  static const String _storageKey = 'chat_history';

  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSending = false;
  bool _historyLoaded = false;
  bool _showDisclaimer = true;

  /// Gemini model used for every reply. Flash-Lite is on the free tier of
  /// the Firebase AI Logic Gemini Developer API.
  static const String _modelName = 'gemini-2.5-flash-lite';

  /// Instructions that shape every reply.
  static const String _systemPrompt =
      'You are a compassionate, supportive AI friend '
      'helping someone on their sobriety journey. Be warm, '
      'encouraging, and non-judgmental. Keep responses concise '
      '(under 120 words) and caring. You are NOT a therapist '
      'but a supportive companion. If someone is in crisis, '
      'encourage them to call a helpline.';

  // ── Welcome Messages ──────────────────────────────────────────────────

  static const String _welcomeMessage =
      'Hi there! I\'m your AI Friend, here to support you 24/7. '
      'Whether you\'re dealing with a craving, need motivation, '
      'or just want someone to talk to — I\'m here for you. '
      'How are you feeling right now?';

  static const List<String> _suggestedPrompts = [
    'I\'m having a craving right now',
    'Remind me why I quit',
    'I need motivation',
    'Tell me a calming story',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    _loadDailyUsage();
    _checkDisclaimer();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Opening or closing the keyboard changes the height left for the message
  /// list, so keep the newest message in view after the relayout.
  @override
  void didChangeMetrics() {
    _scrollToBottom();
  }

  // ── History Persistence ───────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final loaded = list
            .map((e) => _ChatMessage.fromJson(e as Map<String, dynamic>))
            .where((m) => m.text.isNotEmpty)
            .toList();
        if (loaded.isNotEmpty && mounted) {
          setState(() {
            _messages.addAll(loaded);
            _historyLoaded = true;
          });
          _scrollToBottom();
          return;
        }
      } catch (e) {
        debugPrint('[AIChat] Failed to parse chat history: $e');
      }
    }

    // No valid history found — show welcome
    if (mounted) {
      setState(() => _historyLoaded = true);
      _addWelcomeMessage();
    }
  }

  Future<void> _saveHistory() async {
    if (!_historyLoaded) return;

    // Keep only the last 50 messages to avoid hitting SharedPreferences size limits
    if (_messages.length > 50) {
      _messages.removeRange(0, _messages.length - 50);
    }

    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    if (mounted) {
      setState(() => _messages.clear());
      _addWelcomeMessage();
    }
  }

  // ── Daily Message Limit (temporary client-side safeguard) ─────────────
  // A server-side proxy will enforce this later; until then the count lives
  // in SharedPreferences so it survives app restarts.

  static const String _dailyCountKey = 'chat_daily_count';
  static const String _dailyDateKey = 'chat_daily_date';

  int _dailyCount = 0;

  /// Messages left for today, never negative.
  int get _messagesRemaining {
    final remaining = ApiConfig.dailyMessageLimit - _dailyCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Today's calendar day as a `yyyy-mm-dd` key.
  String get _todayKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Loads today's usage. A missing or unreadable value, or a stored date
  /// that is not today, means the day starts fresh at zero.
  Future<void> _loadDailyUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCount = prefs.getInt(_dailyCountKey) ?? 0;
      final storedDate = prefs.getString(_dailyDateKey);
      final used = storedDate == _todayKey && storedCount > 0 ? storedCount : 0;

      if (mounted) setState(() => _dailyCount = used);

      // First run of a new calendar day — reset the stored count.
      if (used == 0 && storedDate != _todayKey) {
        await prefs.setString(_dailyDateKey, _todayKey);
        await prefs.setInt(_dailyCountKey, 0);
      }
    } catch (e) {
      debugPrint('[AIChat] Failed to load daily usage: $e');
      if (mounted) setState(() => _dailyCount = 0);
    }
  }

  /// Counts one user message against today's allowance. A storage failure
  /// still counts in memory so a single session cannot run away.
  Future<void> _recordUserMessage() async {
    final next = _dailyCount + 1;
    if (mounted) setState(() => _dailyCount = next);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dailyDateKey, _todayKey);
      await prefs.setInt(_dailyCountKey, next);
    } catch (e) {
      debugPrint('[AIChat] Failed to save daily usage: $e');
    }
  }

  // ── Welcome ───────────────────────────────────────────────────────────

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(_ChatMessage(
        text: _welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _saveHistory();
  }

  // ── Sending Messages ──────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    // ── Temporary daily limit — show a friendly note instead of calling
    // the API once the day's allowance is used up. ────────────────
    if (_messagesRemaining <= 0) {
      _showDailyLimitMessage();
      return;
    }

    HapticFeedback.lightImpact();

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Count this message against today's allowance.
    await _recordUserMessage();

    // Get AI response
    await _getAIResponse(trimmed);

    // Persist both user message and AI response
    if (mounted) _saveHistory();

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  /// The most recent messages sent as conversation history.
  List<_ChatMessage> get _historyWindow {
    final limit = ApiConfig.historyMessageLimit;
    if (_messages.length <= limit) return _messages;
    return _messages.sublist(_messages.length - limit);
  }

  Future<void> _getAIResponse(String userMessage) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // ── Firebase AI Logic (Gemini) ─────────────────────────────────
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: ApiConfig.maxResponseTokens,
        ),
      );

      // Only the most recent messages travel to Gemini — _sendMessage has
      // already added the user's latest message to _messages.
      final response = await model
          .generateContent(_buildRequestContents(userMessage))
          .timeout(const Duration(seconds: 30));

      final aiText = response.text?.trim();
      _appendAiReply(
        aiText == null || aiText.isEmpty
            ? 'I\'m here for you. Tell me more.'
            : aiText,
      );
    } catch (error) {
      _handleAIError(error, userMessage);
    }
  }

  /// Builds the turns sent to Gemini.
  ///
  /// Gemini rejects a request unless the first turn comes from the user and
  /// the roles then alternate. [_messages] also holds the welcome message (a
  /// `model` turn) and can hold two user turns in a row when a reply failed,
  /// so the raw list is cleaned up before it leaves the device.
  List<Content> _buildRequestContents(String currentUserMessage) {
    final turns = <MapEntry<String, String>>[];

    for (final message in _historyWindow) {
      final text = message.text.trim();
      if (text.isEmpty) continue;
      final role = message.isUser ? 'user' : 'model';
      // A conversation must open with the user — drop leading model turns.
      if (turns.isEmpty && role != 'user') continue;
      if (turns.isNotEmpty && turns.last.key == role) {
        final previous = turns.removeLast();
        turns.add(MapEntry(role, '${previous.value}\n\n$text'));
        continue;
      }
      turns.add(MapEntry(role, text));
    }

    if (turns.isEmpty) {
      final fallback = currentUserMessage.trim();
      if (fallback.isNotEmpty) turns.add(MapEntry('user', fallback));
    }

    return [
      for (final turn in turns) Content(turn.key, [TextPart(turn.value)]),
    ];
  }

  /// Turns any failure into a friendly notice, a short code and the details
  /// shown behind the "Details" action. The raw text is logged as well.
  void _handleAIError(Object error, String userMessage) {
    final details = _errorDetails(error, userMessage);
    debugPrint('[AIChat] $details');

    if (_looksOffline(error) && !_isQuotaError(error)) {
      // Existing offline fallback so the user still gets a caring reply.
      _appendAiReply(_getSimulatedResponse(userMessage));
      _showError(
        'No internet connection. Using offline replies. '
        '(AI-${_errorCode(error)})',
        details: details,
      );
      return;
    }

    _showAIError(_friendlyAIError(error), details: details);
  }

  /// The exception class name, used as the short code on every notice.
  String _errorCode(Object error) {
    final type = error.runtimeType.toString();
    return type.isEmpty ? 'Unknown' : type;
  }

  /// Provider message, without the wrapper added by [Exception.toString].
  String _rawErrorMessage(Object error) {
    if (error is FirebaseAIException) return error.message;
    return error.toString();
  }

  /// Provider message truncated for the Details dialog, with the user's own
  /// text and anything key-shaped removed.
  String _errorDetails(Object error, String userMessage) {
    var message = _rawErrorMessage(error);

    final userText = userMessage.trim();
    if (userText.isNotEmpty) {
      message = message.replaceAll(userText, '[message]');
    }
    message = message.replaceAllMapped(
      RegExp(
        r'\b(api[-_ ]?key|token|secret|authorization|bearer)\b\s*[:=]\s*\S+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=[redacted]',
    );
    message = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (message.length > 300) {
      message = '${message.substring(0, 300)}…';
    }

    return '${_errorCode(error)}: $message';
  }

  /// Maps the Firebase AI Logic exceptions to a short, human message.
  String _friendlyAIError(Object error) {
    final code = _errorCode(error);
    final text = _rawErrorMessage(error).toLowerCase();

    String friendly;
    if (error is ServiceApiNotEnabled ||
        text.contains('not enabled') ||
        text.contains('not been used') ||
        text.contains('service_disabled') ||
        text.contains('no firebase app') ||
        text.contains('has not been created')) {
      friendly = "The AI service isn't enabled yet.";
    } else if (error is InvalidApiKey ||
        text.contains('api key') ||
        text.contains('api_key') ||
        text.contains('permission') ||
        text.contains('unauthenticated') ||
        text.contains('app check') ||
        text.contains('appcheck') ||
        text.contains('403')) {
      friendly = "The AI service couldn't verify this app.";
    } else if (_isQuotaError(error)) {
      friendly = 'The AI is busy right now. Please try again in a few minutes.';
    } else if (error is UnsupportedUserLocation ||
        text.contains('location is not supported') ||
        text.contains('user location')) {
      friendly = "The AI isn't available in your region.";
    } else if (error is TimeoutException) {
      friendly = 'The AI took too long to answer.';
    } else {
      friendly = 'Something went wrong.';
    }

    return '$friendly (AI-$code)';
  }

  /// Adds an AI reply to the conversation and clears the typing indicator.
  void _appendAiReply(String text) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _messages.add(_ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  /// Stops the typing indicator and shows a short, friendly notice.
  void _showAIError(String message, {String? details}) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showError(message, details: details);
  }

  /// Quota / rate-limit failures surface as [QuotaExceeded] or a generic
  /// [FirebaseAIException] whose message names the condition.
  bool _isQuotaError(Object error) {
    if (error is QuotaExceeded) return true;
    final message = error is FirebaseAIException
        ? error.message.toLowerCase()
        : error.toString().toLowerCase();
    return message.contains('quota') ||
        message.contains('rate limit') ||
        message.contains('resource_exhausted') ||
        message.contains('too many requests') ||
        message.contains('429');
  }

  /// Best-effort detection of a connection failure. The SDK wraps platform
  /// network errors differently per platform, so match on the common text.
  bool _looksOffline(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('offline') ||
        message.contains('unavailable');
  }

  // ── Simulated Responses (fallback when API is unavailable) ────────────

  String _getSimulatedResponse(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('crave') ||
        lower.contains('urge') ||
        lower.contains('trigger')) {
      return 'I hear you. Cravings can be really intense, but they usually pass '
          'within 15-20 minutes. Would you like to try a breathing exercise, '
          'or maybe step outside for a short walk? You\'ve got this. 💪';
    }

    if (lower.contains('why') &&
        (lower.contains('quit') || lower.contains('start'))) {
      return 'You quit because you deserve a healthier, happier life. '
          'Think about the reasons you wrote down — your health, your '
          'relationships, your peace of mind. Every sober moment is a '
          'victory. What\'s one reason that matters most to you today?';
    }

    if (lower.contains('motivat') ||
        lower.contains('encourage') ||
        lower.contains('proud')) {
      return 'I\'m so proud of you for being here, working on yourself. '
          'That takes real courage. Remember: every day is a fresh start, '
          'and every step forward counts — no matter how small. '
          'You are stronger than you know. 🌟';
    }

    if (lower.contains('sad') ||
        lower.contains('lonely') ||
        lower.contains('anxious') ||
        lower.contains('scared')) {
      return 'It\'s okay to feel that way. Your feelings are valid. '
          'You\'re not alone in this — I\'m here with you. Take a deep '
          'breath with me. In through your nose... hold... and out '
          'slowly through your mouth. How does that feel?';
    }

    if (lower.contains('thank')) {
      return 'You\'re so welcome! I\'m here for you anytime — 24/7. '
          'Keep going — find your calm, anytime. You\'re doing amazing. 💜';
    }

    if (lower.contains('story') || lower.contains('calm')) {
      return 'Imagine a quiet beach at sunrise. The waves gently lap '
          'against the shore. The sky is painted in soft shades of pink '
          'and gold. You take a deep breath, feeling the cool breeze on '
          'your skin. For this moment, everything is peaceful. You are safe. '
          'You are exactly where you need to be. 🌅';
    }

    return 'Thank you for sharing that with me. I want you to know that '
        'whatever you\'re feeling right now is completely okay. '
        'You\'re doing something incredibly brave by facing this journey '
        'head-on. Is there anything specific you\'d like to talk about, '
        'or would you like me to suggest something to help right now?';
  }

  // ── Disclaimer ──────────────────────────────────────────────────────

  Future<void> _checkDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('ai_disclaimer_shown') ?? false;
    if (mounted) {
      setState(() => _showDisclaimer = !dismissed);
    }
  }

  Future<void> _dismissDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_disclaimer_shown', true);
    if (mounted) {
      setState(() => _showDisclaimer = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Scrolls to the newest message once the current frame has laid out.
  ///
  /// A second pass after the frame handles the keyboard inset, where the
  /// first layout can still report the previous scroll extent.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateToBottom());
    Future.delayed(const Duration(milliseconds: 120), _animateToBottom);
  }

  void _animateToBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          'Clear Chat?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will delete your entire conversation history.',
          style: TextStyle(
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softRed,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _clearHistory();
    }
  }

  void _showError(String message, {String? details}) {
    if (!mounted) return;
    final showDetails = kShowErrorDetails && details != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        // Debug-only escape hatch: the exception type and message live behind
        // this action, never in the visible notice.
        action: showDetails
            ? SnackBarAction(
                label: 'Details',
                textColor: AppColors.white,
                onPressed: () => _showErrorDetailsDialog(details),
              )
            : null,
        backgroundColor: AppColors.softRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        margin: const EdgeInsets.all(AppConstants.spacingMd),
      ),
    );
  }

  /// Dialog behind the SnackBar's "Details" action: selectable, copyable
  /// error text with no keys and no message history.
  Future<void> _showErrorDetailsDialog(String details) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          'Error details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            details,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: details));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Friendly notice shown instead of calling the API once today's limit is
  /// reached. A server-side proxy will enforce this later.
  void _showDailyLimitMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 20,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "You've reached today's chat limit. Come back tomorrow.",
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        margin: const EdgeInsets.all(AppConstants.spacingMd),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // The body shrinks with the keyboard; the input bar is the bottom child,
      // so nothing is ever covered and no manual inset padding is needed.
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              onPressed: () => _confirmClearHistory(context),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
              ),
              tooltip: 'Clear chat history',
            ),
        ],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.brandLightBlue, AppColors.brandPrimary]
                      : [AppColors.brandPrimary, AppColors.brandPrimaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ApiConfig.aiName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.brandLightBlue
                        : AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // A raised keyboard (or a very short screen) can leave less room
          // than the informational rows need. Drop them there so the message
          // list and the input bar always fit instead of overflowing.
          final compact = constraints.maxHeight < 340;
          return Column(
        children: [
          // ── Disclaimer Banner ──────────────────────────────────────
          if (_showDisclaimer && !compact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingXs,
              ),
              color: AppColors.brandLightBlue.withValues(alpha: 0.12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Expanded(
                    child: Text(
                      'I\'m an AI, not a medical professional. '
                      'If you\'re in crisis, please call a helpline.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        // High-contrast text colors — this is safety-critical
                        // copy and must stay readable (brandLightBlue on the
                        // orange-tinted banner was ~1.7:1).
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissDisclaimer,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Messages List ──────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: AppConstants.spacingMd,
                      right: AppConstants.spacingMd,
                      top: AppConstants.spacingMd,
                      bottom: AppConstants.spacingSm,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator(isDark);
                      }

                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        isDark: isDark,
                        isFirstMessage: index == 0,
                      );
                    },
                  ),
          ),

          // ── Suggested Prompts ──────────────────────────────────────
          // Hidden while the keyboard is up so short screens keep room for
          // the conversation instead of overflowing.
          if (_messages.length <= 1 && !_isSending && !compact)
            _buildSuggestedPrompts(isDark),

          // ── Messages Left Today (temporary client-side limit) ──────
          if (!compact) _buildMessagesRemaining(isDark),

          // ── Input Bar ──────────────────────────────────────────────
          _buildInputBar(isDark),
        ],
          );
        },
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 36,
              color: isDark ? AppColors.brandLightBlue : AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'Chat with Your ${ApiConfig.aiName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'I\'m here to support you 24/7.\nStart a conversation below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggested Prompts ─────────────────────────────────────────────────

  Widget _buildSuggestedPrompts(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try asking me…',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textOnDarkSecondary.withValues(alpha: 0.6)
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Wrap(
            spacing: AppConstants.spacingXs,
            runSpacing: AppConstants.spacingXs,
            children: _suggestedPrompts.map((prompt) {
              return GestureDetector(
                onTap: () => _sendMessage(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical: AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardAlt
                        : AppColors.lightGrayAlt,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFull,
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.brandPrimary.withValues(alpha: 0.3)
                          : AppColors.brandPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Typing Indicator ──────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingXs,
        horizontal: AppConstants.spacingXxl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0, isDark: isDark),
                const SizedBox(width: 4),
                _TypingDot(delay: 200, isDark: isDark),
                const SizedBox(width: 4),
                _TypingDot(delay: 400, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages Left Today (temporary client-side limit) ─────────────────

  Widget _buildMessagesRemaining(bool isDark) {
    final bool exhausted = _messagesRemaining <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        0,
        AppConstants.spacingMd,
        AppConstants.spacingXs,
      ),
      child: Text(
        exhausted
            ? 'No messages left today'
            : '$_messagesRemaining of ${ApiConfig.dailyMessageLimit} messages left today',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: exhausted
              ? AppColors.softRed
              : (isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textTertiary),
        ),
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark) {
    return Container(
      // The Scaffold's resize already applies the keyboard inset, so adding
      // MediaQuery.viewInsets here would push the bar up twice. SafeArea
      // covers the gesture/navigation bar when the keyboard is closed.
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardAlt : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusFull,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  maxLines: 4,
                  minLines: 1,
                  // Temporary client-side cap — a server-side proxy will
                  // enforce this later. The formatter keeps the pill clean
                  // (no character counter under the field).
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      ApiConfig.maxMessageLength,
                    ),
                  ],
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                          : AppColors.textTertiary,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                  onSubmitted: (_) {
                    if (_textController.text.trim().isNotEmpty) {
                      _sendMessage(_textController.text);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),

            // Send Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _textController.text.trim().isEmpty || _isSending
                    ? null
                    : () => _sendMessage(_textController.text),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                child: AnimatedContainer(
                  duration: AppConstants.animationFast,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _textController.text.trim().isEmpty
                        ? (isDark
                            ? AppColors.darkCardAlt
                            : AppColors.lightGrayAlt)
                        : (isDark ? AppColors.brandLightBlue : AppColors.brandPrimary),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.brandPrimary
                                : AppColors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: _textController.text.trim().isEmpty
                              ? (isDark
                                  ? AppColors.textOnDarkSecondary
                                      .withValues(alpha: 0.4)
                                  : AppColors.textTertiary)
                              : (isDark
                                  ? AppColors.brandPrimary
                                  : AppColors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ──────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final bool isFirstMessage;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    this.isFirstMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppConstants.spacingXs,
        top: isFirstMessage ? 0 : 0,
      ),
      child: Align(
        alignment: message.isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: message.isUser
                  ? (isDark ? AppColors.brandLightBlue : AppColors.brandPrimary)
                  : (isDark ? AppColors.darkCardAlt : AppColors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppConstants.radiusLg),
                topRight: const Radius.circular(AppConstants.radiusLg),
                bottomLeft: message.isUser
                    ? const Radius.circular(AppConstants.radiusLg)
                    : const Radius.circular(AppConstants.radiusSm),
                bottomRight: message.isUser
                    ? const Radius.circular(AppConstants.radiusSm)
                    : const Radius.circular(AppConstants.radiusLg),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.shadowDark : AppColors.shadowLight)
                      .withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // AI avatar
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.brandLightBlue
                                : AppColors.brandPrimary,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 10,
                            color: isDark
                                ? AppColors.brandPrimary
                                : AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ApiConfig.aiName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.brandLightBlue
                                : AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message text
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: message.isUser
                        ? (isDark ? AppColors.brandPrimary : AppColors.white)
                        : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Typing Animation Dot ─────────────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final int delay;
  final bool isDark;

  const _TypingDot({required this.delay, required this.isDark});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (widget.isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textTertiary)
                .withValues(alpha: _anim.value),
          ),
        );
      },
    );
  }
}
