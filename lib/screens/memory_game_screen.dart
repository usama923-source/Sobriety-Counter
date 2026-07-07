import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

// ── Card Model ───────────────────────────────────────────────────────────

class _MemoryCard {
  final String emoji;
  bool isFlipped = false;
  bool isMatched = false;

  _MemoryCard({required this.emoji});
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

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initGame();
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
                        color: AppColors.skyBlue.withValues(alpha: 0.15),
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
                        ? AppColors.navyBlueDark
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
                backgroundColor: AppColors.successGreen,
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
