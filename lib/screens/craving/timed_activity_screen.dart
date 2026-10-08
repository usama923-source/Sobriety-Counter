import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// A reusable countdown screen for timed craving activities (walking,
/// drinking water, etc.).
///
/// Shows a pulsing icon header, a countdown timer with a progress bar,
/// Start/Reset controls, and a completion celebration card. Previously this
/// logic was duplicated in walk_screen.dart and drink_water_screen.dart.
class TimedActivityScreen extends StatefulWidget {
  /// AppBar title and header heading (e.g. "Go for a Walk").
  final String title;

  /// Subtitle shown under the header (e.g. why this activity helps).
  final String message;

  /// Accent color for the icon, progress bar, and buttons.
  final Color color;

  /// Icon shown in the pulsing header circle.
  final IconData icon;

  /// Total countdown duration in minutes.
  final int durationMinutes;

  const TimedActivityScreen({
    super.key,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.durationMinutes,
  });

  @override
  State<TimedActivityScreen> createState() => _TimedActivityScreenState();
}

class _TimedActivityScreenState extends State<TimedActivityScreen>
    with SingleTickerProviderStateMixin {
  late final int _totalSeconds = widget.durationMinutes * 60;

  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isComplete = false;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress => 1.0 - (_remainingSeconds / _totalSeconds);

  void _startTimer() {
    if (_isRunning) return;
    // If the previous run finished, start over from the full duration
    // instead of immediately re-completing at 0.
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _totalSeconds;
    }
    setState(() {
      _isRunning = true;
      _isComplete = false;
    });
    HapticFeedback.lightImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _isComplete = true;
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isComplete = false;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.color;

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
          widget.title,
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
              // ── Pulsing Icon Card ──────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingXxl,
                  horizontal: AppConstants.spacingLg,
                ),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _isRunning ? _pulseAnim.value : 1.0,
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(
                                alpha: isDark ? 0.15 : 0.1,
                              ),
                            ),
                            child: Icon(
                              _isComplete
                                  ? Icons.check_circle_rounded
                                  : widget.icon,
                              size: 48,
                              color: _isComplete
                                  ? AppColors.successGreen
                                  : accent,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLg),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Timer Card ─────────────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingXl,
                  horizontal: AppConstants.spacingLg,
                ),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: Column(
                  children: [
                    // ── Time Display ───────────────────────────────────
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: 3,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'minutes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Progress Bar ───────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: accent.withValues(
                          alpha: isDark ? 0.12 : 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isComplete ? AppColors.successGreen : accent,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingSm),

                    // ── Hint ───────────────────────────────────────────
                    Text(
                      _isRunning
                          ? '${(_remainingSeconds ~/ 60 + 1)} min left — keep going!'
                          : '${widget.durationMinutes} minute activity',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Start / Reset Buttons ──────────────────────────
                    Row(
                      children: [
                        // Start Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isRunning ? null : _startTimer,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull,
                              ),
                              child: AnimatedContainer(
                                duration: AppConstants.animationFast,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.spacingMd,
                                ),
                                decoration: BoxDecoration(
                                  color: context.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusFull,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isComplete
                                              ? AppColors.successGreen
                                              : accent)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border(
                                    bottom: BorderSide(
                                      color: context.primary,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _isComplete ? 'Completed' : 'Start',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: context.onPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),

                        // Reset Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _resetTimer,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.spacingMd,
                                ),
                                decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightGrayAlt,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusFull,
                                    ),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.textOnDarkSecondary
                                              .withValues(alpha: 0.2)
                                          : AppColors.textTertiary
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                child: Center(
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textOnDarkSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Completion Message ─────────────────────────────────────
              if (_isComplete) ...[
                const SizedBox(height: AppConstants.spacingLg),
                SoberCard(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: AppColors.successGreen.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  hasShadow: false,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.successGreen.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          size: 24,
                          color: AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          'Amazing! You beat that craving!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
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
}
