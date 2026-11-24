import '../../../core/network/api_client.dart';
import 'shift_model.dart';

class ShiftApiService {
  const ShiftApiService();

  Future<List<Shift>> getShifts({String? search, String? status}) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final path = Uri(path: '/shifts', queryParameters: query).toString();
    final response = await ApiClient.get(path);
    final data = response['data'] as List;

    return data
        .map((json) => Shift.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Shift> getShift(int id) async {
    final response = await ApiClient.get('/shifts/$id');

    return Shift.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Shift> createShift({
    required String name,
    String? shiftType,
    String? description,
    required String startTime,
    required String endTime,
    String status = 'active',
    int breakDurationMinutes = 15,
    int gracePeriodMinutes = 10,
    required List<int> scheduledDays,
  }) async {
    final response = await ApiClient.postJson(
      path: '/shifts',
      body: {
        'name': name,
        'shift_type': shiftType,
        'description': description,
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        'break_duration_minutes': breakDurationMinutes,
        'grace_period_minutes': gracePeriodMinutes,
        'scheduled_days': scheduledDays,
      },
    );

    return Shift.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Shift> updateShift({
    required int shiftId,
    required String name,
    String? shiftType,
    String? description,
    required String startTime,
    required String endTime,
    String status = 'active',
    int breakDurationMinutes = 15,
    int gracePeriodMinutes = 10,
    required List<int> scheduledDays,
  }) async {
    final response = await ApiClient.patchJson(
      path: '/shifts/$shiftId',
      body: {
        'name': name,
        'shift_type': shiftType,
        'description': description,
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        'break_duration_minutes': breakDurationMinutes,
        'grace_period_minutes': gracePeriodMinutes,
        'scheduled_days': scheduledDays,
      },
    );

    return Shift.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Shift> changeShiftStatus({
    required int shiftId,
    required String status,
  }) async {
    final response = await ApiClient.patchJson(
      path: '/shifts/$shiftId/status',
      body: {'status': status},
    );

    return Shift.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteShift(int shiftId) async {
    await ApiClient.delete('/shifts/$shiftId');
  }
}
