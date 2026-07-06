import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

// ── Breathing phase enum ───────────────────────────────────────────────
enum _BreathPhase { inhale, hold, exhale }

/// Breathing Exercise screen — a full-screen guided breathing session.
/// Inhale 4s → Hold 4s → Exhale 6s = 14s per cycle × 5 cycles = 70s total.
/// Animated circle expands/shrinks with soothing color transitions.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  // ── Breathing cycle constants ─────────────────────────────────────
  static const double _inhaleSec = 4;
  static const double _holdSec = 4;
  static const double _exhaleSec = 6;
  static const int _totalCycles = 5;

  // ── State ─────────────────────────────────────────────────────────
  bool _isActive = false;
  bool _isComplete = false;
  int _currentCycle = 0;
  _BreathPhase _currentPhase = _BreathPhase.inhale;
  Timer? _phaseTimer;
  DateTime? _phaseStart;

  // ── Animation ─────────────────────────────────────────────────────
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  // ── Phase colors ──────────────────────────────────────────────────
  Color get _currentColor {
    switch (_currentPhase) {
      case _BreathPhase.inhale:
        return const Color(0xFF7EC8C3); // softTeal
      case _BreathPhase.hold:
        return AppColors.skyBlueLight;
      case _BreathPhase.exhale:
        return AppColors.successGreenLight;
    }
  }

  String get _phaseLabel {
    switch (_currentPhase) {
      case _BreathPhase.inhale:
        return 'Breathe In';
      case _BreathPhase.hold:
        return 'Hold';
      case _BreathPhase.exhale:
        return 'Breathe Out';
    }
  }

  String get _phaseInstruction {
    switch (_currentPhase) {
      case _BreathPhase.inhale:
        return 'Slowly breathe in through your nose…';
      case _BreathPhase.hold:
        return 'Gently hold your breath…';
      case _BreathPhase.exhale:
        return 'Slowly release through your mouth…';
    }
  }

  double get _currentPhaseDuration {
    switch (_currentPhase) {
      case _BreathPhase.inhale:
        return _inhaleSec;
      case _BreathPhase.hold:
        return _holdSec;
      case _BreathPhase.exhale:
        return _exhaleSec;
    }
  }

  double get _progress {
    if (!_isActive || _currentCycle == 0) return 0.0;
    final phaseProgress = _phaseStart != null
        ? (DateTime.now().difference(_phaseStart!).inMilliseconds /
                (_currentPhaseDuration * 1000))
            .clamp(0.0, 1.0)
        : 0.0;
    return (_currentCycle - 1 + phaseProgress) / _totalCycles;
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  // ── Controls ──────────────────────────────────────────────────────

  void _start() {
    setState(() {
      _isActive = true;
      _currentCycle = 1;
      _currentPhase = _BreathPhase.inhale;
    });
    _startPhase();
  }

  void _stop() {
    _phaseTimer?.cancel();
    _scaleController.reset();
    setState(() {
      _isActive = false;
      _currentCycle = 0;
      _phaseStart = null;
    });
  }

  void _startPhase() {
    _phaseTimer?.cancel();
    _phaseStart = DateTime.now();

    HapticFeedback.mediumImpact();

    final durationMs = (_currentPhaseDuration * 1000).toInt();
    _scaleController.duration = Duration(milliseconds: durationMs);

    switch (_currentPhase) {
      case _BreathPhase.inhale:
        _scaleController.forward(from: 0.0);
        break;
      case _BreathPhase.hold:
        _scaleController.value = 1.0;
        break;
      case _BreathPhase.exhale:
        _scaleController.reverse(from: 1.0);
        break;
    }

    _phaseTimer = Timer(
      Duration(milliseconds: durationMs),
      _onPhaseComplete,
    );

    setState(() {});
  }

  void _onPhaseComplete() {
    if (!mounted || !_isActive) return;

    setState(() {
      switch (_currentPhase) {
        case _BreathPhase.inhale:
          _currentPhase = _BreathPhase.hold;
          break;
        case _BreathPhase.hold:
          _currentPhase = _BreathPhase.exhale;
          break;
        case _BreathPhase.exhale:
          if (_currentCycle >= _totalCycles) {
            _finish();
            return;
          }
          _currentCycle++;
          _currentPhase = _BreathPhase.inhale;
          break;
      }
    });

    _startPhase();
  }

  void _finish() {
    _phaseTimer?.cancel();
    _scaleController.reset();
    HapticFeedback.heavyImpact();
    setState(() {
      _isActive = false;
      _currentCycle = 0;
      _phaseStart = null;
      _isComplete = true;
    });
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
          'Breathing Exercise',
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
              // ── Header Icon Card ──────────────────────────────────────
              SoberCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingXxl,
                  horizontal: AppConstants.spacingLg,
                ),
                color: isDark
                    ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                    : AppColors.white,
                hasShadow: true,
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.softOrange.withValues(
                          alpha: isDark ? 0.15 : 0.1,
                        ),
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        size: 48,
                        color: AppColors.softOrange,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text(
                      'Take 5 Deep Breaths',
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
                      'Inhale, hold, and exhale slowly.\nLet the circle guide you.',
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
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // ── Breathing Circle Card ─────────────────────────────────
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
                    // ── Animated Breathing Circle ─────────────────────
                    Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnim,
                        builder: (context, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 600),
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentColor
                                            .withValues(
                                                alpha: isDark ? 0.06 : 0.08),
                                      ),
                                    ),
                                    // Animated circle
                                    Transform.scale(
                                      scale: _isActive
                                          ? _scaleAnim.value
                                          : 0.7,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 600),
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              _currentColor
                                                  .withValues(alpha: 0.9),
                                              _currentColor,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _currentColor
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 40,
                                              spreadRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            child: Text(
                                              _phaseLabel,
                                              key: ValueKey(
                                                '${_currentPhase.index}_$_currentCycle',
                                              ),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingMd),
                              // Phase instruction
                              AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 300),
                                child: Text(
                                  _isActive
                                      ? _phaseInstruction
                                      : 'Press Start to begin your session',
                                  key: ValueKey(
                                      'instr_${_currentPhase.index}_$_isActive'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Progress Bar ──────────────────────────────────
                    if (_isActive) ...[
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusFull),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: _currentColor.withValues(
                              alpha: isDark ? 0.12 : 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _currentColor),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'Cycle $_currentCycle of $_totalCycles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _currentColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingLg),
                    ],

                    // ── Control Buttons ───────────────────────────────
                    Row(
                      children: [
                        // Start / Stop Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isActive ? _stop : _start,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull,
                              ),
                              child: AnimatedContainer(
                                duration: AppConstants.animationFast,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.spacingMd,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isActive
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.softRed,
                                            AppColors.softRedLight,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : _isComplete
                                          ? const LinearGradient(
                                              colors: [
                                                AppColors.successGreen,
                                                AppColors.successGreenLight,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                AppColors.softOrange,
                                                AppColors.softOrangeLight,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusFull,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isActive
                                              ? AppColors.softRed
                                              : _isComplete
                                                  ? AppColors.successGreen
                                                  : AppColors.softOrange)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isActive
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(
                                        width: AppConstants.spacingXs),
                                    Text(
                                      _isActive ? 'Stop' : 'Start',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isActive) ...[
                          const SizedBox(width: AppConstants.spacingMd),
                          // Reset Button
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _isComplete = false);
                                },
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
                      ],
                    ),
                  ],
                ),
              ),

              // ── Completion Message ──────────────────────────────────
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
                          color:
                              AppColors.successGreen.withValues(alpha: 0.15),
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
                          'Beautiful! You completed 5 cycles.',
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
