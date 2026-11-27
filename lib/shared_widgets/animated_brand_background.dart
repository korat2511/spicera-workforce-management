import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A full-bleed animated gradient backdrop (drifting blobs, bubbles and
/// light streaks) used behind brand moments like the splash and login
/// screens. Renders [child] on top of the animation.
class AnimatedBrandBackground extends StatefulWidget {
  const AnimatedBrandBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBrandBackground> createState() =>
      _AnimatedBrandBackgroundState();
}

class _AnimatedBrandBackgroundState extends State<AnimatedBrandBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bubble> _bubbles;
  late final List<_Streak> _streaks;

  @override
  void initState() {
    super.initState();

    final random = math.Random();
    _bubbles = List.generate(16, (_) => _Bubble.random(random));
    _streaks = List.generate(5, (_) => _Streak.random(random));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _AnimatedBackgroundPainter(
                  t: _controller.value,
                  bubbles: _bubbles,
                  streaks: _streaks,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Bubble {
  _Bubble({
    required this.dx,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.driftAmplitude,
    required this.driftFrequency,
    required this.opacity,
  });

  factory _Bubble.random(math.Random random) {
    return _Bubble(
      dx: random.nextDouble(),
      radius: 10 + random.nextDouble() * 34,
      speed: 0.4 + random.nextDouble() * 0.8,
      phase: random.nextDouble(),
      driftAmplitude: 10 + random.nextDouble() * 30,
      driftFrequency: 1 + random.nextDouble() * 2,
      opacity: 0.35 + random.nextDouble() * 0.45,
    );
  }

  final double dx;
  final double radius;
  final double speed;
  final double phase;
  final double driftAmplitude;
  final double driftFrequency;
  final double opacity;
}

class _Streak {
  _Streak({
    required this.dy,
    required this.speed,
    required this.phase,
    required this.length,
    required this.thickness,
    required this.opacity,
    required this.angle,
  });

  factory _Streak.random(math.Random random) {
    return _Streak(
      dy: random.nextDouble(),
      speed: 0.15 + random.nextDouble() * 0.25,
      phase: random.nextDouble(),
      length: 140 + random.nextDouble() * 160,
      thickness: 1.5 + random.nextDouble() * 1.5,
      opacity: 0.25 + random.nextDouble() * 0.3,
      angle: -0.35 + random.nextDouble() * 0.2,
    );
  }

  final double dy;
  final double speed;
  final double phase;
  final double length;
  final double thickness;
  final double opacity;
  final double angle;
}

double _edgeFade(double progress) {
  if (progress < 0.12) return progress / 0.12;
  if (progress > 0.85) return (1 - progress) / 0.15;
  return 1;
}

class _AnimatedBackgroundPainter extends CustomPainter {
  _AnimatedBackgroundPainter({
    required this.t,
    required this.bubbles,
    required this.streaks,
  });

  final double t;
  final List<_Bubble> bubbles;
  final List<_Streak> streaks;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryPressed, AppColors.primary],
        ).createShader(rect),
    );

    final angle = t * 2 * math.pi;

    _drawBlob(
      canvas,
      size,
      dx: 0.25 + 0.16 * math.sin(angle),
      dy: 0.2 + 0.12 * math.cos(angle * 1.1),
      radius: size.shortestSide * 0.4,
      color: AppColors.secondary.withValues(alpha: 0.35),
    );
    _drawBlob(
      canvas,
      size,
      dx: 0.8 + 0.12 * math.cos(angle * 0.8),
      dy: 0.75 + 0.14 * math.sin(angle * 1.3),
      radius: size.shortestSide * 0.38,
      color: AppColors.tertiary.withValues(alpha: 0.3),
    );

    for (final streak in streaks) {
      _drawStreak(canvas, size, streak);
    }

    for (final bubble in bubbles) {
      _drawBubble(canvas, size, bubble);
    }
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required double dx,
    required double dy,
    required double radius,
    required Color color,
  }) {
    final center = Offset(dx * size.width, dy * size.height);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawBubble(Canvas canvas, Size size, _Bubble bubble) {
    final progress = (t * bubble.speed + bubble.phase) % 1.0;
    final fade = _edgeFade(progress) * bubble.opacity;
    if (fade <= 0) return;

    final y = size.height * (1.15 - progress * 1.3);
    final x =
        size.width * bubble.dx +
        bubble.driftAmplitude *
            math.sin(2 * math.pi * progress * bubble.driftFrequency);
    final center = Offset(x, y);

    canvas.drawCircle(
      center,
      bubble.radius,
      Paint()..color = AppColors.onPrimary.withValues(alpha: fade * 0.25),
    );
    canvas.drawCircle(
      center,
      bubble.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = AppColors.onPrimary.withValues(alpha: fade),
    );
    canvas.drawCircle(
      Offset(center.dx - bubble.radius * 0.3, center.dy - bubble.radius * 0.3),
      bubble.radius * 0.25,
      Paint()..color = AppColors.onPrimary.withValues(alpha: fade * 0.6),
    );
  }

  void _drawStreak(Canvas canvas, Size size, _Streak streak) {
    final progress = (t * streak.speed + streak.phase) % 1.0;
    final travel = size.width + streak.length;
    final centerX = -streak.length / 2 + travel * progress;
    final centerY = size.height * streak.dy;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(streak.angle);

    final halfLength = streak.length / 2;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.onPrimary.withValues(alpha: 0),
          AppColors.onPrimary.withValues(alpha: streak.opacity),
          AppColors.onPrimary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(-halfLength, 0, streak.length, 1))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = streak.thickness;

    canvas.drawLine(Offset(-halfLength, 0), Offset(halfLength, 0), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter oldDelegate) =>
      oldDelegate.t != t;
}
