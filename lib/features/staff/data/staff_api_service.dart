import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/utils/date_time_utils.dart';
import 'staff_list_page.dart';
import 'staff_model.dart';

class StaffApiService {
  const StaffApiService();

  Future<StaffListPage> getStaffList({
    String? search,
    String? status,
    String? employmentType,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
      'status': ?status,
      'employment_type': ?employmentType,
    };

    final path = Uri(path: '/staff', queryParameters: query).toString();
    final response = await ApiClient.get(path);

    return StaffListPage.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Staff> getStaff(int staffId) async {
    final response = await ApiClient.get('/staff/$staffId');

    return Staff.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Staff> createStaff({
    required String firstName,
    required String lastName,
    required String phone,
    required String employmentType,
    required DateTime joiningDate,
    required String salaryType,
    required double salaryRate,
    String overtimeRateType = 'not_eligible',
    String? overtimeCustomType,
    double? overtimeCustomRate,
    double? dailyHourLimit,
    double? weeklyHourLimit,
    double? monthlyHourLimit,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    String? streetAddress,
    String? suburb,
    String? state,
    String? postcode,
    String? jobTitle,
    String? notes,
    File? profilePhoto,
  }) async {
    final fields = <String, String>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'employment_type': employmentType,
      'joining_date': DateTimeUtils.toApiDate(joiningDate),
      'salary_type': salaryType,
      'salary_rate': salaryRate.toStringAsFixed(2),
      'overtime_rate_type': overtimeRateType,
      'overtime_custom_type': ?overtimeCustomType,
      if (overtimeCustomRate != null)
        'overtime_custom_rate': overtimeCustomRate.toStringAsFixed(2),
      if (dailyHourLimit != null)
        'daily_hour_limit': dailyHourLimit.toStringAsFixed(2),
      if (weeklyHourLimit != null)
        'weekly_hour_limit': weeklyHourLimit.toStringAsFixed(2),
      if (monthlyHourLimit != null)
        'monthly_hour_limit': monthlyHourLimit.toStringAsFixed(2),
      if (email != null && email.isNotEmpty) 'email': email,
      if (dateOfBirth != null)
        'date_of_birth': DateTimeUtils.toApiDate(dateOfBirth),
      'gender': ?gender,
      if (streetAddress != null && streetAddress.isNotEmpty)
        'street_address': streetAddress,
      if (suburb != null && suburb.isNotEmpty) 'suburb': suburb,
      'state': ?state,
      if (postcode != null && postcode.isNotEmpty) 'postcode': postcode,
      if (jobTitle != null && jobTitle.isNotEmpty) 'job_title': jobTitle,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await ApiClient.postMultipart(
      path: '/staff',
      fields: fields,
      file: profilePhoto,
    );

    return Staff.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Staff> updateStaff({
    required int staffId,
    required String firstName,
    required String lastName,
    required String phone,
    required String employmentType,
    required DateTime joiningDate,
    required String salaryType,
    required double salaryRate,
    String overtimeRateType = 'not_eligible',
    String? overtimeCustomType,
    double? overtimeCustomRate,
    double? dailyHourLimit,
    double? weeklyHourLimit,
    double? monthlyHourLimit,
    String? email,
    String? jobTitle,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'employment_type': employmentType,
      'joining_date': DateTimeUtils.toApiDate(joiningDate),
      'salary_type': salaryType,
      'salary_rate': salaryRate.toStringAsFixed(2),
      'overtime_rate_type': overtimeRateType,
      'overtime_custom_type': ?overtimeCustomType,
      if (overtimeCustomRate != null)
        'overtime_custom_rate': overtimeCustomRate.toStringAsFixed(2),
      if (dailyHourLimit != null)
        'daily_hour_limit': dailyHourLimit.toStringAsFixed(2),
      if (weeklyHourLimit != null)
        'weekly_hour_limit': weeklyHourLimit.toStringAsFixed(2),
      if (monthlyHourLimit != null)
        'monthly_hour_limit': monthlyHourLimit.toStringAsFixed(2),
      if (email != null && email.isNotEmpty) 'email': email,
      if (jobTitle != null && jobTitle.isNotEmpty) 'job_title': jobTitle,
    };

    final response = await ApiClient.patchJson(
      path: '/staff/$staffId',
      body: body,
    );

    return Staff.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Sets, changes, or (when [pin] is omitted) clears the staff member's
  /// attendance PIN. [currentPin] is required by the backend whenever the
  /// staff member already has a PIN and [pin] is being changed to a new one.
  Future<Staff> setPin({
    required int staffId,
    String? pin,
    String? pinConfirmation,
    String? currentPin,
  }) async {
    final response = await ApiClient.patchJson(
      path: '/staff/$staffId/pin',
      body: {
        'pin': ?pin,
        'pin_confirmation': ?pinConfirmation,
        'current_pin': ?currentPin,
      },
    );

    return Staff.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Checks [pin] against the staff member's current PIN without changing
  /// it — used to validate a "current PIN" step before collecting a new one.
  Future<bool> verifyPin({required int staffId, required String pin}) async {
    final response = await ApiClient.postJson(
      path: '/staff/$staffId/pin/verify',
      body: {'pin': pin},
    );

    final data = response['data'] as Map<String, dynamic>;
    return data['matches'] as bool;
  }

  Future<Staff> changeStatus({
    required int staffId,
    required String status,
  }) async {
    final response = await ApiClient.patchJson(
      path: '/staff/$staffId/status',
      body: {'status': status},
    );

    return Staff.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Staff> assignShift({required int staffId, int? shiftId}) async {
    final response = await ApiClient.patchJson(
      path: '/staff/$staffId/shift',
      body: {'shift_id': shiftId},
    );

    return Staff.fromJson(response['data'] as Map<String, dynamic>);
  }
}
