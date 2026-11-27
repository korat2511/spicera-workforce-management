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
    fontSize: 40,
    fontWeight: FontWeight.w700,
    lineHeight: 48,
    letterSpacing: -0.8,
    color: color,
  );

  static TextStyle displayLgMobile({Color? color}) => _style(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    lineHeight: 40,
    letterSpacing: -0.64,
    color: color,
  );

  static TextStyle headlineLg({Color? color}) => _style(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    lineHeight: 38,
    letterSpacing: -0.45,
    color: color,
  );

  static TextStyle headlineMd({Color? color}) => _style(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    lineHeight: 32,
    letterSpacing: -0.24,
    color: color,
  );

  static TextStyle headlineSm({Color? color}) => _style(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    lineHeight: 28,
    letterSpacing: -0.1,
    color: color,
  );

  static TextStyle titleMd({Color? color}) => _style(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    lineHeight: 26,
    color: color,
  );

  static TextStyle bodyLg({Color? color}) => _style(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    lineHeight: 26,
    color: color,
  );

  static TextStyle bodyMd({Color? color}) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    lineHeight: 24,
    color: color,
  );

  static TextStyle bodySm({Color? color}) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    lineHeight: 20,
    color: color,
  );

  static TextStyle labelLg({Color? color}) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    lineHeight: 24,
    letterSpacing: 0.16,
    color: color,
  );

  static TextStyle labelMd({Color? color}) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    lineHeight: 20,
    letterSpacing: 0.26,
    color: color,
  );

  static TextStyle labelSm({Color? color}) => _style(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    lineHeight: 18,
    letterSpacing: 0.35,
    color: color,
  );

  static TextStyle tabularNums(TextStyle style) {
    return style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
