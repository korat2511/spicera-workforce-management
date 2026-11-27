import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoUtils {
  DeviceInfoUtils._();

  static final _plugin = DeviceInfoPlugin();

  /// Returns (platform, model) describing the current physical device,
  /// e.g. ('iOS', "Rutvik's iPhone (iOS 17.4)") or
  /// ('Android', 'samsung SM-G998B (Android 14)').
  static Future<(String, String)> current() async {
    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      return ('iOS', '${info.name} (${info.systemName} ${info.systemVersion})');
    }

    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      return (
        'Android',
        '${info.manufacturer} ${info.model} (Android ${info.version.release})',
      );
    }

    return (Platform.operatingSystem, 'Unknown device');
  }
}
