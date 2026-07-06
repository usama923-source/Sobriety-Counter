import 'dart:math';
import 'package:flutter/material.dart';

/// A lightweight confetti celebration overlay that uses Flutter's built-in
/// animation capabilities (no external packages). Trigger by passing a
/// unique [key] to rebuild and animate confetti particles.
///
/// Usage:
/// ```dart
/// ConfettiCelebration(key: ValueKey('milestone_$day')),
/// ```
class ConfettiCelebration extends StatefulWidget {
  /// Number of confetti particles.
  final int particleCount;

  /// Duration of the confetti animation.
  final Duration duration;

  /// Custom colors. Defaults to a celebration palette.
  final List<Color>? colors;

  const ConfettiCelebration({
    super.key,
    this.particleCount = 40,
    this.duration = const Duration(seconds: 3),
    this.colors,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _particles = _generateParticles();
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.key != oldWidget.key) {
      _controller.reset();
      _particles = _generateParticles();
      _controller.forward();
    }
  }

  List<_ConfettiParticle> _generateParticles() {
    final rng = Random(widget.key.hashCode);
    final defaultColors = [
      const Color(0xFF4CAF50), // successGreen
      const Color(0xFFFFB74D), // softOrange
      const Color(0xFF7FB3D5), // skyBlue
      const Color(0xFF7EC8C3), // softTeal
      const Color(0xFFEF5350), // softRed
      const Color(0xFFFFD89B), // softOrangeLight
      const Color(0xFF81C784), // successGreenLight
      const Color(0xFFA8D0E6), // skyBlueLight
    ];
    final colors = widget.colors ?? defaultColors;

    return List.generate(widget.particleCount, (i) {
      return _ConfettiParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 4,
        size: rng.nextDouble() * 8 + 4,
        color: colors[rng.nextInt(colors.length)],
        speed: rng.nextDouble() * 0.4 + 0.6,
        horizontalDrift: (rng.nextDouble() - 0.5) * 0.3,
        shape: rng.nextInt(3), // 0=circle, 1=square, 2=line
      );
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
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
  final double speed;
  final double horizontalDrift;
  final int shape;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.speed,
    required this.horizontalDrift,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pProgress = ((progress - p.y * 0.3) / p.speed).clamp(0.0, 1.0);
      if (pProgress <= 0.0 || pProgress >= 1.0) continue;

      final fadeOut = (1.0 - pProgress).clamp(0.0, 1.0);
      final alpha = (fadeOut * 255).toInt();
      final color = p.color.withValues(alpha: alpha / 255.0);

      final x = size.width * p.x + size.width * p.horizontalDrift * pProgress;
      final y = size.height * (pProgress * 0.8) + pProgress * pProgress * 100;
      final rotation = p.rotation + p.rotationSpeed * pProgress * 3;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()..color = color;
      final halfSize = p.size / 2;

      switch (p.shape) {
        case 0: // circle
          canvas.drawCircle(Offset.zero, halfSize, paint);
        case 1: // square
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
        case 2: // line
          canvas.drawLine(
            Offset(-halfSize, 0),
            Offset(halfSize, 0),
            paint..strokeWidth = 2,
          );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A convenient wrapper that shows confetti when [show] is true.
class ConfettiOverlay extends StatefulWidget {
  final bool show;
  final Widget child;
  final int particleCount;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    required this.show,
    required this.child,
    this.particleCount = 40,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  int _celebrationKey = 0;

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      setState(() => _celebrationKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiCelebration(
                key: ValueKey('confetti_$_celebrationKey'),
                particleCount: widget.particleCount,
                duration: widget.duration,
              ),
            ),
          ),
      ],
    );
  }
}
