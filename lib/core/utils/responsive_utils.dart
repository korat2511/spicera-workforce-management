import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveUtils {
  ResponsiveUtils._();

  static const double mobileBreakpoint = 768;
  static const double desktopBreakpoint = 1200;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static DeviceType deviceType(BuildContext context) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= mobileBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final horizontal = value<double>(
      context,
      mobile: AppSpacing.margin,
      tablet: AppSpacing.marginTablet,
      desktop: AppSpacing.marginDesktop,
    );
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  static double gutter(BuildContext context) {
    return value<double>(
      context,
      mobile: AppSpacing.gutter,
      tablet: AppSpacing.gutterTablet,
      desktop: AppSpacing.gutterDesktop,
    );
  }

  static int gridColumns(BuildContext context) {
    return value<int>(context, mobile: 1, tablet: 8, desktop: 12);
  }
}
