import '../../../core/network/api_client.dart';
import '../../../core/utils/device_info_utils.dart';
import 'kiosk_device_model.dart';

class KioskDeviceApiService {
  const KioskDeviceApiService();

  Future<List<KioskDevice>> list() async {
    final response = await ApiClient.get('/kiosk-devices');
    final data = response['data'] as List;
    return data
        .map((e) => KioskDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Registers a new kiosk device and returns the one-time plaintext token
  /// (never retrievable again) alongside the created device.
  Future<(KioskDevice, String)> register(String name) async {
    final (platform, model) = await DeviceInfoUtils.current();

    final response = await ApiClient.postJson(
      path: '/kiosk-devices',
      body: {'name': name, 'platform': platform, 'model': model},
    );
    final data = response['data'] as Map<String, dynamic>;
    final device = KioskDevice.fromJson(data['device'] as Map<String, dynamic>);
    final token = data['token'] as String;
    return (device, token);
  }

  Future<void> revoke(int deviceId) async {
    await ApiClient.delete('/kiosk-devices/$deviceId');
  }
}
