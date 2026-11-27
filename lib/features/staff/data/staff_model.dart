import 'shift_model.dart';

class Staff {
  const Staff({
    required this.id,
    required this.staffCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.email,
    required this.phone,
    required this.employmentType,
    this.jobTitle,
    required this.joiningDate,
    required this.salaryType,
    required this.salaryRate,
    this.overtimeRateType = 'not_eligible',
    this.overtimeCustomType,
    this.overtimeCustomRate,
    this.overtimeLabel = 'Not eligible',
    required this.currency,
    required this.status,
    this.profilePhotoUrl,
    this.pinSet = false,
    this.shift,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as int,
      staffCode: json['staff_code'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      employmentType: json['employment_type'] as String,
      jobTitle: json['job_title'] as String?,
      joiningDate: json['joining_date'] as String,
      salaryType: json['salary_type'] as String,
      salaryRate: json['salary_rate'] as String,
      overtimeRateType: json['overtime_rate_type'] as String? ?? 'not_eligible',
      overtimeCustomType: json['overtime_custom_type'] as String?,
      overtimeCustomRate: json['overtime_custom_rate'] as String?,
      overtimeLabel: json['overtime_label'] as String? ?? 'Not eligible',
      currency: json['currency'] as String,
      status: json['status'] as String,
      profilePhotoUrl: json['profile_photo'] as String?,
      pinSet: json['pin_set'] as bool? ?? false,
      shift: json['shift'] == null
          ? null
          : Shift.fromJson(json['shift'] as Map<String, dynamic>),
    );
  }

  final int id;
  final String staffCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? email;
  final String phone;
  final String employmentType;
  final String? jobTitle;
  final String joiningDate;
  final String salaryType;
  final String salaryRate;
  final String overtimeRateType;
  final String? overtimeCustomType;
  final String? overtimeCustomRate;
  final String overtimeLabel;
  final String currency;
  final String status;
  final String? profilePhotoUrl;
  final bool pinSet;
  final Shift? shift;
}
