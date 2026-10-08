import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Card Model ───────────────────────────────────────────────────────────

class _MemoryCard {
  final String emoji;
  bool isFlipped = false;
  bool isMatched = false;

  _MemoryCard({required this.emoji});
}

// ── Game Record Model ────────────────────────────────────────────────────

/// A single completed-game result persisted in SharedPreferences.
class _GameRecord {
  final DateTime date;
  final int flips;
  final int seconds;

  const _GameRecord({
    required this.date,
    required this.flips,
    required this.seconds,
  });

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'flips': flips,
        'seconds': seconds,
      };

  factory _GameRecord.fromJson(Map<String, dynamic> json) => _GameRecord(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        flips: (json['flips'] as num).toInt(),
        seconds: (json['seconds'] as num).toInt(),
      );
}

// ── Screen ───────────────────────────────────────────────────────────────

/// A 4×4 card matching memory game to help beat cravings.
///
/// Flip cards to find matching emoji pairs. A timer counts up and displays
/// the completion time when all pairs are found.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  // ── Constants ──────────────────────────────────────────────────────
  static const List<String> _emojis = [
    '🌊', '🌿', '🌸', '🍃',
    '🌙', '⭐', '🦋', '🕊️',
  ];
  static const int _gridColumns = 4;
  static const Duration _flipDelay = Duration(milliseconds: 1000);

  // ── Game State ─────────────────────────────────────────────────────
  List<_MemoryCard> _cards = [];
  List<int> _flippedIndices = [];
  bool _isProcessing = false;
  bool _isComplete = false;
  int _matchCount = 0;
  int _flipCount = 0;

  // ── Timer ──────────────────────────────────────────────────────────
  int _elapsedSeconds = 0;
  Timer? _gameTimer;

  // ── History ────────────────────────────────────────────────────────
  static const String _historyKey = 'memory_game_history';
  static const int _historyLimit = 50;
  List<_GameRecord> _history = [];

  String get _formattedTime => _formatSeconds(_elapsedSeconds);

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Best result so far (fewest flips, then fastest time), if any.
  _GameRecord? get _bestRecord {
    if (_history.isEmpty) return null;
    final sorted = [..._history]..sort((a, b) {
        final byFlips = a.flips.compareTo(b.flips);
        return byFlips != 0 ? byFlips : a.seconds.compareTo(b.seconds);
      });
    return sorted.first;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initGame();
    _loadHistory();
  }

  // ── History Persistence ─────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = list
          .map((e) => _GameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() => _history = loaded);
      }
    } catch (e) {
      debugPrint('[MemoryGame] Failed to load history: $e');
    }
  }

  Future<void> _saveResult() async {
    try {
      final updated = [
        ..._history,
        _GameRecord(
          date: DateTime.now(),
          flips: _flipCount,
          seconds: _elapsedSeconds,
        ),
      ];
      // Keep only the most recent [_historyLimit] games.
      final trimmed = updated.length > _historyLimit
          ? updated.sublist(updated.length - _historyLimit)
          : updated;

      if (mounted) {
        setState(() => _history = trimmed);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyKey,
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[MemoryGame] Failed to save result: $e');
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  // ── Game Logic ─────────────────────────────────────────────────────

  void _initGame() {
    final random = Random();
    final emojiPairs = [..._emojis, ..._emojis]..shuffle(random);

    _cards = List.generate(
      emojiPairs.length,
      (i) => _MemoryCard(emoji: emojiPairs[i]),
    );
    _flippedIndices = [];
    _isProcessing = false;
    _isComplete = false;
    _matchCount = 0;
    _flipCount = 0;
    _elapsedSeconds = 0;
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _startTimer() {
    if (_gameTimer != null) return;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;

    if (_gameTimer == null) _startTimer();

    HapticFeedback.lightImpact();

    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
      _flipCount++;
    });

    if (_flippedIndices.length == 2) {
      _isProcessing = true;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final first = _cards[_flippedIndices[0]];
    final second = _cards[_flippedIndices[1]];

    if (first.emoji == second.emoji) {
      // Match found
      HapticFeedback.mediumImpact();
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        _matchCount++;
        _flippedIndices = [];
        _isProcessing = false;
      });

      if (_matchCount == _emojis.length) {
        _handleWin();
      }
    } else {
      // No match — flip back after a delay
      Future.delayed(_flipDelay, () {
        if (!mounted) return;
        setState(() {
          first.isFlipped = false;
          second.isFlipped = false;
          _flippedIndices = [];
          _isProcessing = false;
        });
      });
    }
  }

  void _handleWin() {
    _gameTimer?.cancel();
    _gameTimer = null;
    HapticFeedback.heavyImpact();

    setState(() => _isComplete = true);
    _saveResult();
  }

  void _restart() {
    setState(() {
      _initGame();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Memory Game',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingLg,
          ),
          child: Column(
            children: [
              // ── Header Card ──────────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingLg,
                  horizontal: AppConstants.spacingLg,
                ),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.softTeal.withValues(alpha: 0.15),
                      ),
                      child: const Text(
                        '🧠',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Match the Pairs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Flip cards to find matching emoji pairs.\nFocus your mind, beat the craving!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // ── Stats Row ──────────────────────────────────────
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                            icon: Icons.timer_outlined,
                            label: _formattedTime,
                            isDark: isDark,
                          ),
                          const SizedBox(width: AppConstants.spacingMd),
                          _StatChip(
                            icon: Icons.touch_app_rounded,
                            label: '$_flipCount flips',
                            isDark: isDark,
                          ),
                          const SizedBox(width: AppConstants.spacingMd),
                          _StatChip(
                            icon: Icons.check_circle_outline,
                            label: '$_matchCount/${_emojis.length}',
                            isDark: isDark,
                          ),
                          if (_bestRecord != null) ...[
                            const SizedBox(width: AppConstants.spacingMd),
                            _StatChip(
                              icon: Icons.emoji_events_rounded,
                              label:
                                  'Best ${_bestRecord!.flips} flips | ${_formatSeconds(_bestRecord!.seconds)}',
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Game Grid Card ───────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: _isComplete
                    ? _buildWinScreen(isDark)
                    : _buildGrid(isDark),
              ),

              // ── Restart Button ───────────────────────────────────────
              if (!_isComplete) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Restart Game'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkCardAlt
                            : AppColors.lightGrayAlt,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingMd,
                      ),
                    ),
                  ),
                ),
              ],

              // ── History ──────────────────────────────────────────────
              if (_history.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SoberCard(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: isDark
                      ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                      : AppColors.white,
                  hasShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: AppColors.navyBlue,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            'Recent Games',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_history.length} played',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      ..._history.reversed.take(10).map((record) {
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                        ];
                        final dateStr =
                            '${months[record.date.month - 1]} ${record.date.day}';
                        final isBest = identical(record, _bestRecord) ||
                            (record.flips == _bestRecord!.flips &&
                                record.seconds == _bestRecord!.seconds &&
                                record.date == _bestRecord!.date);
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingXs,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingMd,
                              vertical: AppConstants.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightGray,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSm,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isBest) ...[
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    size: 16,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${record.flips} flips \u00b7 ${_formatSeconds(record.seconds)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Game Grid ──────────────────────────────────────────────────────

  Widget _buildGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        crossAxisSpacing: AppConstants.spacingSm,
        mainAxisSpacing: AppConstants.spacingSm,
        childAspectRatio: 0.85,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) => _buildCard(isDark, index),
    );
  }

  Widget _buildCard(bool isDark, int index) {
    final card = _cards[index];
    final isFaceUp = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          color: isFaceUp
              ? (isDark ? AppColors.darkCard : Colors.white)
              : (isDark ? AppColors.navyBlue.withValues(alpha: 0.6) : AppColors.navyBlue),
          gradient: isFaceUp
              ? null
              : LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.navyBlue.withValues(alpha: 0.6),
                          AppColors.navyBlueLight.withValues(alpha: 0.4),
                        ]
                      : [
                          AppColors.navyBlue,
                          AppColors.navyBlueLight,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            if (card.isMatched)
              BoxShadow(
                color: AppColors.successGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            if (!isFaceUp)
              BoxShadow(
                color: (isDark
                        ? AppColors.navyBlue
                        : AppColors.navyBlue)
                    .withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: isFaceUp
            ? Center(
                child: AnimatedScale(
                  scale: isFaceUp ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    card.emoji,
                    style: TextStyle(
                      fontSize: card.isMatched ? 36 : 32,
                    ),
                  ),
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Win Screen ─────────────────────────────────────────────────────

  Widget _buildWinScreen(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingLg,
      ),
      child: Column(
        children: [
          // Celebration icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppColors.successGreen,
                  AppColors.successGreenLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Win message
          Text(
            'Amazing! You beat that craving!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // Completion time
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Text(
                  'Completed in $_formattedTime',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            '$_flipCount card flips | ${_emojis.length} pairs matched',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Restart button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMd,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardAlt.withValues(alpha: 0.5)
            : AppColors.lightGrayAlt,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
