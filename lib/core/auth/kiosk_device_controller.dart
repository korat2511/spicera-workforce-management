import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class KioskDeviceController extends ValueNotifier<String?> {
  KioskDeviceController() : super(null);

  static const String _prefsKey = 'kiosk_device_token';
  static const String _deviceIdPrefsKey = 'kiosk_device_id';

  bool get isPaired => value != null;
  int? pairedDeviceId;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsKey);
    ApiClient.setKioskToken(token);
    pairedDeviceId = prefs.getInt(_deviceIdPrefsKey);
    value = token;
  }

  Future<void> pair({required int deviceId, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, token);
    await prefs.setInt(_deviceIdPrefsKey, deviceId);
    ApiClient.setKioskToken(token);
    pairedDeviceId = deviceId;
    value = token;
  }

  Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_deviceIdPrefsKey);
    ApiClient.setKioskToken(null);
    pairedDeviceId = null;
    value = null;
  }
}

final kioskDeviceController = KioskDeviceController();
