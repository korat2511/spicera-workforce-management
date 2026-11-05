import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.tertiary,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.secondary,
      icon: Icons.warning_amber_outlined,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.textPrimary,
      icon: Icons.info_outline,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
          ),
          margin: const EdgeInsets.all(AppSpacing.md),
          content: Row(
            children: [
              Icon(icon, color: AppColors.onPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMd(color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
