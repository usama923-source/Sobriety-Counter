import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

// ── Breathing phase enum (outside class for proper Dart 3 support) ─────
enum _BreathPhase { inhale, hold, exhale }

/// Section 7 — Guided Breathing Exercise.
///
/// Inhale 4s → Hold 4s → Exhale 6s = 14s per cycle × 5 cycles = 70s total.
/// Animated circle expands/shrinks with soothing color transitions.
/// HapticFeedback on each phase change. Optional sound toggle.
class GuidedBreathingCard extends StatefulWidget {
  const GuidedBreathingCard({super.key});

  @override
  State<GuidedBreathingCard> createState() => _GuidedBreathingCardState();
}

class _GuidedBreathingCardState extends State<GuidedBreathingCard>
    with SingleTickerProviderStateMixin {
  // ── Breathing cycle constants ─────────────────────────────────────
  static const double _inhaleSec = 4;
  static const double _holdSec = 4;
  static const double _exhaleSec = 6;
  static const int _totalCycles = 5;

  // ── State ─────────────────────────────────────────────────────────
  bool _isActive = false;
  int _currentCycle = 0;
  _BreathPhase _currentPhase = _BreathPhase.inhale;
  bool _soundEnabled = false;
  Timer? _phaseTimer;
  DateTime? _phaseStart;

  // ── Animation ─────────────────────────────────────────────────────
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  // ── Phase colors ──────────────────────────────────────────────────
  static const Color _inhaleColor = Color(0xFF7EC8C3);    // softTeal
  static const Color _holdColor = Color(0xFFA8D0E6);     // skyBlueLight
  static const Color _exhaleColor = Color(0xFF81C784);    // successGreenLight

  Color get _currentColor {
    switch (_currentPhase) {
      case _BreathPhase.inhale: return _inhaleColor;
      case _BreathPhase.hold:   return _holdColor;
      case _BreathPhase.exhale: return _exhaleColor;
    }
  }

  String get _phaseLabel {
    switch (_currentPhase) {
      case _BreathPhase.inhale: return 'Breathe In';
      case _BreathPhase.hold:   return 'Hold';
      case _BreathPhase.exhale: return 'Breathe Out';
    }
  }

  String get _phaseInstruction {
    switch (_currentPhase) {
      case _BreathPhase.inhale: return 'Slowly breathe in through your nose…';
      case _BreathPhase.hold:   return 'Gently hold your breath…';
      case _BreathPhase.exhale: return 'Slowly release through your mouth…';
    }
  }

  double get _currentPhaseDuration {
    switch (_currentPhase) {
      case _BreathPhase.inhale: return _inhaleSec;
      case _BreathPhase.hold:   return _holdSec;
      case _BreathPhase.exhale: return _exhaleSec;
    }
  }

  /// Overall progress (0..1) across all cycles.
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

    // Trigger haptic on phase change
    HapticFeedback.mediumImpact();

    // Play a soft system sound if enabled
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    // Update animation controller duration to match this phase
    final durationMs = (_currentPhaseDuration * 1000).toInt();
    _scaleController.duration = Duration(milliseconds: durationMs);

    switch (_currentPhase) {
      case _BreathPhase.inhale:
        _scaleController.forward(from: 0.0);
        break;
      case _BreathPhase.hold:
        // Keep circle at full size
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.skyBlue.withValues(alpha: 0.2)
                      : AppColors.skyBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  size: 22,
                  color: AppColors.skyBlue,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Guided Breathing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              // Sound toggle
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _soundEnabled = !_soundEnabled);
                    if (_soundEnabled) {
                      SystemSound.play(SystemSoundType.click);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Animated Breathing Circle ───────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentColor
                                .withValues(alpha: isDark ? 0.06 : 0.08),
                          ),
                        ),
                        // Animated circle
                        Transform.scale(
                          scale: _isActive ? _scaleAnim.value : 0.7,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _currentColor.withValues(alpha: 0.9),
                                  _currentColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _currentColor.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _phaseLabel,
                                  key: ValueKey(
                                    '${_currentPhase.index}_$_currentCycle',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
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
                    const SizedBox(height: AppConstants.spacingMd),
                    // Phase instruction
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isActive
                            ? _phaseInstruction
                            : 'Press Start to begin a 5-cycle session',
                        key: ValueKey('instr_${_currentPhase.index}_$_isActive'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
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

          // ── Progress ────────────────────────────────────────────────
          if (_isActive) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor:
                    isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_currentColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Cycle $_currentCycle of $_totalCycles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _currentColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
          ],

          // ── Start / Stop Button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActive ? _stop : _start,
              icon: Icon(
                _isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
              label: Text(_isActive ? 'Stop Session' : 'Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isActive ? AppColors.softRed : AppColors.softTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
              ),
            ),
          ),

          // ── Sound state indicator ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.spacingSm),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                        : AppColors.textTertiary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _soundEnabled ? 'Soft sounds on' : 'Soft sounds off',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                          : AppColors.textTertiary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
