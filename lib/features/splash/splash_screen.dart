import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../shared_widgets/animated_brand_background.dart';
import '../attendance/gate_screen.dart';
import '../shell/main_shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _footerOpacity;

  late final Timer _redirectTimer;

  @override
  void initState() {
    super.initState();

    _redirectTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        NavigationUtils.pushReplacement(
          authController.isLoggedIn
              ? const MainShellScreen()
              : const GateScreen(),
          context: context,
        );
      }
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
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
    _sweepController.dispose();
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
      body: AnimatedBrandBackground(
        child: SafeArea(
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
                      style: AppTypography.displayLg(color: AppColors.onPrimary)
                          .copyWith(
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
                        animation: _sweepController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _SweepProgressPainter(
                              _sweepController.value,
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
      ),
    );
  }
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
