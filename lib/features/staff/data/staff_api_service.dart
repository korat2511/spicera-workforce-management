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

  Future<Staff> setPin({
    required int staffId,
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await ApiClient.patchJson(
      path: '/staff/$staffId/pin',
      body: {'pin': pin, 'pin_confirmation': pinConfirmation},
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
