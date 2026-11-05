import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required double lineHeight,
    double letterSpacing = 0,
    Color? color,
  }) {
    return GoogleFonts.beVietnamPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight / fontSize,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle displayLg({Color? color}) => _style(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    lineHeight: 44,
    letterSpacing: -0.72,
    color: color,
  );

  static TextStyle displayLgMobile({Color? color}) => _style(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    lineHeight: 36,
    letterSpacing: -0.56,
    color: color,
  );

  static TextStyle headlineLg({Color? color}) => _style(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    lineHeight: 36,
    letterSpacing: -0.42,
    color: color,
  );

  static TextStyle headlineMd({Color? color}) => _style(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    lineHeight: 30,
    letterSpacing: -0.22,
    color: color,
  );

  static TextStyle headlineSm({Color? color}) => _style(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    lineHeight: 26,
    letterSpacing: -0.09,
    color: color,
  );

  static TextStyle titleMd({Color? color}) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    lineHeight: 24,
    color: color,
  );

  static TextStyle bodyLg({Color? color}) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    lineHeight: 24,
    color: color,
  );

  static TextStyle bodyMd({Color? color}) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    lineHeight: 20,
    color: color,
  );

  static TextStyle bodySm({Color? color}) => _style(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    lineHeight: 16,
    color: color,
  );

  static TextStyle labelLg({Color? color}) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    lineHeight: 20,
    letterSpacing: 0.14,
    color: color,
  );

  static TextStyle labelMd({Color? color}) => _style(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    lineHeight: 16,
    letterSpacing: 0.24,
    color: color,
  );

  static TextStyle labelSm({Color? color}) => _style(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    lineHeight: 14,
    letterSpacing: 0.33,
    color: color,
  );

  static TextStyle tabularNums(TextStyle style) {
    return style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
