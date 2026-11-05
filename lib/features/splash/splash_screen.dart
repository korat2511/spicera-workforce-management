import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../shell/main_shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _backgroundController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _footerOpacity;

  late final List<_Bubble> _bubbles;
  late final List<_Streak> _streaks;
  late final Timer _redirectTimer;

  @override
  void initState() {
    super.initState();

    final random = math.Random();
    _bubbles = List.generate(16, (_) => _Bubble.random(random));
    _streaks = List.generate(5, (_) => _Streak.random(random));

    _redirectTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        NavigationUtils.pushReplacement(
          const MainShellScreen(),
          context: context,
        );
      }
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
      ),
    );
    _footerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _redirectTimer.cancel();
    _entranceController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = ResponsiveUtils.value<double>(
      context,
      mobile: 96,
      tablet: 128,
      desktop: 140,
    );
    final titleFontSize = ResponsiveUtils.value<double>(
      context,
      mobile: 34,
      tablet: 52,
      desktop: 60,
    );
    final taglineFontSize = ResponsiveUtils.value<double>(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 22,
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AnimatedBackgroundPainter(
                    t: _backgroundController.value,
                    bubbles: _bubbles,
                    streaks: _streaks,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _entranceController,
                      _pulseController,
                    ]),
                    builder: (context, _) {
                      final pulse = 1 + 0.03 * _pulseController.value;
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value * pulse,
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.panel,
                              ),
                              boxShadow: AppShadows.level3,
                            ),
                            child: Icon(
                              Icons.punch_clock,
                              color: AppColors.primary,
                              size: logoSize * 0.48,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: Text(
                        'Spicera Workforce',
                        style:
                            AppTypography.displayLg(
                              color: AppColors.onPrimary,
                            ).copyWith(
                              fontSize: titleFontSize,
                              letterSpacing: -0.02 * titleFontSize,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeTransition(
                    opacity: _footerOpacity,
                    child: Text(
                      'Attendance & Payroll, Simplified',
                      style: AppTypography.bodyLg(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                      ).copyWith(fontSize: taglineFontSize),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeTransition(
                    opacity: _footerOpacity,
                    child: SizedBox(
                      width: 160,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: AnimatedBuilder(
                          animation: _backgroundController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _SweepProgressPainter(
                                (_backgroundController.value * 4) % 1,
                              ),
                            );
                          },
                        ),
                      ),
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

class _SweepProgressPainter extends CustomPainter {
  _SweepProgressPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.onPrimary.withValues(alpha: 0.3),
    );

    final barWidth = size.width * 0.35;
    final start = (size.width + barWidth) * progress - barWidth;
    canvas.drawRect(
      Rect.fromLTWH(start, 0, barWidth, size.height),
      Paint()..color = AppColors.onPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant _SweepProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
