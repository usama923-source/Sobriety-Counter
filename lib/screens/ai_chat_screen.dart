import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
/// API credentials are configured in [ApiConfig] (lib/config/api_config.dart).
/// To get an API key, visit https://console.groq.com/keys
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  // ── State ─────────────────────────────────────────────────────────────

  static const String _storageKey = 'chat_history';

  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSending = false;
  bool _historyLoaded = false;
  bool _showDisclaimer = true;

  /// Whether a real API key is configured (vs. the placeholder value).
  bool get _hasRealApiKey => ApiConfig.hasRealApiKey;

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
    _loadHistory();
    _checkDisclaimer();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    debugPrint('API Key exists: $_hasRealApiKey');
    debugPrint('Sending to: ${ApiConfig.apiUrl}');

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

    // Get AI response
    await _getAIResponse(trimmed);

    // Persist both user message and AI response
    if (mounted) _saveHistory();

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _getAIResponse(String userMessage) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    // ── Placeholder mode — no real API key, simulate a response ──────
    if (!_hasRealApiKey) {
      await Future.delayed(const Duration(milliseconds: 800));
      final aiText = _getSimulatedResponse(userMessage);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(_ChatMessage(
            text: aiText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
      return;
    }

    try {
      // ── Real API Call (Groq / OpenAI-compatible) ────────────────────

      final response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': ApiConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a compassionate, supportive AI friend '
                  'helping someone on their sobriety journey. Be warm, '
                  'encouraging, and non-judgmental. Keep responses concise '
                  '(under 120 words) and caring. You are NOT a therapist '
                  'but a supportive companion. If someone is in crisis, '
                  'encourage them to call a helpline.',
            },
            // Send all conversation history — _sendMessage already added
            // the user's latest message to _messages before calling us.
            ..._messages.map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                }),
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      )
      .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices']?[0]?['message']?['content']
            ?.toString()
            .trim() ??
            'I\'m here for you. Tell me more.';

        if (mounted) {
          setState(() {
            _isLoading = false;
            _messages.add(_ChatMessage(
              text: aiText,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        }
        return;
      }

      // ── Non-200 — log the status and Groq error body (never the key) ─
      final errorBody = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      debugPrint('[AIChat] HTTP ${response.statusCode}: $errorBody');

      // Show a short, specific message — never the raw response body.
      final String message;
      if (response.statusCode == 401) {
        message = 'The AI service key is invalid';
      } else if (response.statusCode == 404) {
        message = "The AI model isn't available";
      } else if (response.statusCode == 429) {
        message = 'Too many requests, try again in a minute';
      } else {
        message = 'Something went wrong (code ${response.statusCode})';
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showError(message);
      }
    } on TimeoutException catch (e) {
      debugPrint('[AIChat] Request timed out: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('The AI took too long to answer');
      }
    } catch (e) {
      // A connection failure means the device has no internet — keep the
      // offline simulated reply so the user still gets a response.
      if (e is http.ClientException) {
        debugPrint('[AIChat] Offline: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _messages.add(_ChatMessage(
              text: _getSimulatedResponse(userMessage),
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _showError('No internet connection. Using offline replies.');
        }
        return;
      }

      debugPrint('[AIChat] Unexpected error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Something went wrong');
      }
    }
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.softRed,
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
                      ? [AppColors.softTealLight, AppColors.softTeal]
                      : [AppColors.navyBlue, AppColors.navyBlueLight],
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
                  _hasRealApiKey ? 'Online' : 'Offline replies',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        _hasRealApiKey ? AppColors.softTeal : AppColors.softOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── API Config Notice (only when using placeholder key) ─────
          if (!_hasRealApiKey)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingXs,
              ),
              color: AppColors.softOrange.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.softOrange,
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Expanded(
                    child: Text(
                      'Using offline replies. Set your Groq API key in lib/config/api_config.dart to enable AI chat.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.softOrange.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Disclaimer Banner ──────────────────────────────────────
          if (_showDisclaimer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingXs,
              ),
              color: AppColors.softOrange.withValues(alpha: 0.12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.softOrange,
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
                        // copy and must stay readable (softOrange on the
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
                        color: AppColors.softOrange.withValues(alpha: 0.6),
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
          if (_messages.length <= 1 && !_isSending)
            _buildSuggestedPrompts(isDark),

          // ── Input Bar ──────────────────────────────────────────────
          _buildInputBar(isDark),
        ],
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
              color: AppColors.navyBlue.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 36,
              color: isDark ? AppColors.softTealLight : AppColors.navyBlue,
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
                          ? AppColors.navyBlue.withValues(alpha: 0.3)
                          : AppColors.navyBlue.withValues(alpha: 0.15),
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

  // ── Input Bar ─────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        bottomInset + AppConstants.spacingSm,
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
                        : (isDark ? AppColors.softTealLight : AppColors.navyBlue),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.navyBlue
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
                                  ? AppColors.navyBlue
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
                  ? (isDark ? AppColors.softTealLight : AppColors.navyBlue)
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
                                ? AppColors.softTealLight
                                : AppColors.navyBlue,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 10,
                            color: isDark
                                ? AppColors.navyBlue
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
                                ? AppColors.softTealLight
                                : AppColors.navyBlue,
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
                        ? (isDark ? AppColors.navyBlue : AppColors.white)
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
