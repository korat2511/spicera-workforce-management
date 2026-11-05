import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.displayLg(color: AppColors.textPrimary),
      headlineLarge: AppTypography.headlineLg(color: AppColors.textPrimary),
      headlineMedium: AppTypography.headlineMd(color: AppColors.textPrimary),
      headlineSmall: AppTypography.headlineSm(color: AppColors.textPrimary),
      titleMedium: AppTypography.titleMd(color: AppColors.textPrimary),
      bodyLarge: AppTypography.bodyLg(color: AppColors.textPrimary),
      bodyMedium: AppTypography.bodyMd(color: AppColors.textSecondary),
      bodySmall: AppTypography.bodySm(color: AppColors.textMuted),
      labelLarge: AppTypography.labelLg(color: AppColors.textPrimary),
      labelMedium: AppTypography.labelMd(color: AppColors.textSecondary),
      labelSmall: AppTypography.labelSm(color: AppColors.textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      fontFamily: textTheme.bodyLarge?.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size(64, AppSpacing.minTouchTargetLarge),
              textStyle: AppTypography.labelLg(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.base),
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                AppColors.primaryPressed,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.ghostButtonBackground,
          foregroundColor: AppColors.ghostButtonText,
          side: const BorderSide(color: AppColors.ghostButtonBorder),
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          textStyle: AppTypography.labelLg(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          textStyle: AppTypography.labelLg(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTypography.bodyLg(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMd(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: const BorderSide(
            color: AppColors.inputFocusBorder,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.panel),
        ),
        titleTextStyle: AppTypography.headlineSm(color: AppColors.textPrimary),
        contentTextStyle: AppTypography.bodyMd(color: AppColors.textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
