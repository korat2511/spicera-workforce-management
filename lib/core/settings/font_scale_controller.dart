import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleController extends ValueNotifier<double> {
  FontScaleController() : super(defaultScale);

  static const String _prefsKey = 'font_scale';
  static const double min = 0.85;
  static const double max = 1.3;
  static const double defaultScale = 1.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getDouble(_prefsKey) ?? defaultScale;
  }

  Future<void> setScale(double scale) async {
    value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, scale);
  }
}

final fontScaleController = FontScaleController();
