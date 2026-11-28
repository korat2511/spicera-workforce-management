import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/utils/date_time_utils.dart';
import 'attendance_record_model.dart';

class AttendanceApiService {
  const AttendanceApiService();

  Future<AttendanceRecord> punch({
    required String pin,
    required File photo,
  }) async {
    final response = await ApiClient.postMultipart(
      path: '/attendance/punch',
      fields: {'pin': pin},
      file: photo,
      fileFieldName: 'photo',
    );

    return AttendanceRecord.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<AttendanceRecord>> list({
    String? search,
    String? status,
    int? staffId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int perPage = 100,
  }) async {
    final query = <String, String>{
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
      'status': ?status,
      if (staffId != null) 'staff_id': '$staffId',
      if (dateFrom != null) 'date_from': DateTimeUtils.toApiDate(dateFrom),
      if (dateTo != null) 'date_to': DateTimeUtils.toApiDate(dateTo),
    };

    final path = Uri(path: '/attendance', queryParameters: query).toString();
    final response = await ApiClient.get(path);
    final data = response['data'] as Map<String, dynamic>;
    final attendance = data['attendance'] as List;

    return attendance
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
