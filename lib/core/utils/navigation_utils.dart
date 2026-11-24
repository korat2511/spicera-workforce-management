import 'package:flutter/material.dart';

class NavigationUtils {
  NavigationUtils._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext get _context => navigatorKey.currentContext!;

  static Future<T?> push<T>(Widget page, {BuildContext? context}) {
    return Navigator.of(
      context ?? _context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  static Future<T?> pushReplacement<T, TO>(
    Widget page, {
    BuildContext? context,
  }) {
    return Navigator.of(
      context ?? _context,
    ).pushReplacement<T, TO>(MaterialPageRoute(builder: (_) => page));
  }

  static Future<T?> pushAndRemoveUntil<T>(
    Widget page, {
    BuildContext? context,
  }) {
    return Navigator.of(context ?? _context).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  static void pop<T>([T? result, BuildContext? context]) {
    final navigator = Navigator.of(context ?? _context);
    if (navigator.canPop()) {
      navigator.pop<T>(result);
    }
  }

  static bool canPop({BuildContext? context}) {
    return Navigator.of(context ?? _context).canPop();
  }

  static void popToRoot({BuildContext? context}) {
    Navigator.of(context ?? _context).popUntil((route) => route.isFirst);
  }
}
