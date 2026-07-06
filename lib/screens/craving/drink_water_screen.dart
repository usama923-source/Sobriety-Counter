import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Drink Water screen — a calming 5-minute countdown timer to help
/// users ride out a craving by hydrating and grounding themselves.
class DrinkWaterScreen extends StatefulWidget {
  const DrinkWaterScreen({super.key});

  @override
  State<DrinkWaterScreen> createState() => _DrinkWaterScreenState();
}

class _DrinkWaterScreenState extends State<DrinkWaterScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 5 * 60; // 5 minutes

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
          'Drink Water',
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
              // ── Water Drop Icon ──────────────────────────────────────────
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
                              color: AppColors.skyBlue.withValues(
                                alpha: isDark ? 0.15 : 0.1,
                              ),
                            ),
                            child: Icon(
                              _isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.water_drop_rounded,
                              size: 48,
                              color: _isComplete
                                  ? AppColors.successGreen
                                  : AppColors.skyBlue,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLg),
                          Text(
                            'Drink Water',
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
                            'Drinking water reduces cravings.\nThirst often feels like a craving.',
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
                    // ── Circular Progress ────────────────────────────────
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 8,
                              backgroundColor: AppColors.skyBlue.withValues(
                                alpha: isDark ? 0.12 : 0.1,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isComplete
                                    ? AppColors.successGreen
                                    : AppColors.skyBlue,
                              ),
                            ),
                          ),
                          // Time text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formattedTime,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: 2,
                                  color: isDark
                                      ? AppColors.textOnDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'minutes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                                            AppColors.skyBlue,
                                            AppColors.softTeal,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusFull,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isComplete
                                              ? AppColors.successGreen
                                              : AppColors.skyBlue)
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
                          'Well done! How do you feel now?',
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
