import 'package:flutter/material.dart';

import '../../core/auth/kiosk_device_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared_widgets/animated_brand_background.dart';
import '../auth/login_screen.dart';
import 'attendance_camera_screen.dart';

/// Shown after the splash screen when no admin is logged in on this device.
/// The shared-device entry point: staff self-serve attendance here, admins
/// drill into "Login as Admin" for the full management app.
class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  void _markAttendance(BuildContext context) {
    if (!kioskDeviceController.isPaired) {
      SnackbarUtils.showError(
        context,
        "This device isn't set up for attendance yet. Ask an admin to "
        'pair it from Login as Admin → More → Kiosk Devices.',
      );
      return;
    }

    NavigationUtils.push(const AttendanceCameraScreen(), context: context);
  }

  void _loginAsAdmin(BuildContext context) {
    NavigationUtils.push(const LoginScreen(), context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  ResponsiveUtils.screenPadding(context) +
                  const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.panel),
                        boxShadow: AppShadows.level3,
                      ),
                      child: const Icon(
                        Icons.punch_clock,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Spicera Workforce',
                      style: AppTypography.headlineMd(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Select an option to continue',
                      style: AppTypography.bodyLg(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _GateOption(
                      icon: Icons.fingerprint,
                      title: 'Mark Attendance',
                      subtitle: 'For staff — check in or out with your PIN',
                      filled: true,
                      onTap: () => _markAttendance(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GateOption(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Login as Admin',
                      subtitle: 'Manage staff, shifts & payroll',
                      filled: false,
                      onTap: () => _loginAsAdmin(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GateOption extends StatelessWidget {
  const _GateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = filled ? AppColors.textPrimary : AppColors.onPrimary;
    final subtitleColor = filled
        ? AppColors.textMuted
        : AppColors.onPrimary.withValues(alpha: 0.8);
    final iconBackground = filled
        ? AppColors.surfaceHighlight
        : AppColors.onPrimary.withValues(alpha: 0.15);
    final iconColor = filled ? AppColors.primary : AppColors.onPrimary;

    return Material(
      color: filled ? AppColors.onPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: filled
                ? null
                : Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
            boxShadow: filled ? AppShadows.level3 : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSm(color: titleColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMd(color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: titleColor),
            ],
          ),
        ),
      ),
    );
  }
}
