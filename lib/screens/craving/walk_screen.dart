import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Walk screen — a 10-minute countdown timer to encourage users to
/// step outside and walk, reducing cravings through movement.
class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 10 * 60; // 10 minutes

  int _remainingSeconds = _totalSeconds;
  bool _isRunning = false;
  bool _isComplete = false;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
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
          'Go for a Walk',
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
              // ── Walking Icon Card ────────────────────────────────────────
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
                              color: AppColors.successGreen.withValues(
                                alpha: isDark ? 0.15 : 0.1,
                              ),
                            ),
                            child: Icon(
                              _isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.directions_walk_rounded,
                              size: 48,
                              color: _isComplete
                                  ? AppColors.successGreen
                                  : AppColors.successGreen,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLg),
                          Text(
                            'Go for a Walk',
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
                            'A short walk can reduce cravings\nby up to 60%. Step outside!',
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

              // ── Timer Card ──────────────────────────────────────────────
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
                    // ── Time Display ─────────────────────────────────────
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

                    // ── Progress Bar ─────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: AppColors.successGreen.withValues(
                          alpha: isDark ? 0.12 : 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isComplete
                              ? AppColors.successGreen
                              : AppColors.successGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingSm),

                    // ── Step count hint ───────────────────────────────────
                    Text(
                      _isRunning
                          ? '${(_remainingSeconds ~/ 60 + 1)} min left — keep moving!'
                          : '10 minutes = ~1,000 steps',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Start / Reset Buttons ─────────────────────────────
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
                                  gradient: _isComplete
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.successGreen,
                                            AppColors.successGreenLight,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            AppColors.successGreen,
                                            AppColors.successGreenLight,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusFull,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.successGreen
                                          .withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _isComplete ? 'Completed' : 'Start',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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

              // ── Completion Message ──────────────────────────────────────
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
