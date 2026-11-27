class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.type,
    required this.recordedAt,
    this.status,
    this.photoUrl,
    required this.staffFullName,
    required this.staffCode,
    this.shiftName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'] as Map<String, dynamic>;
    final shift = json['shift'] as Map<String, dynamic>?;

    return AttendanceRecord(
      id: json['id'] as int,
      type: json['type'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      status: json['status'] as String?,
      photoUrl: json['photo_url'] as String?,
      staffFullName: staff['full_name'] as String,
      staffCode: staff['staff_code'] as String,
      shiftName: shift?['name'] as String?,
    );
  }

  final int id;

  /// 'check_in' or 'check_out'.
  final String type;

  /// UTC instant — call `.toLocal()` before formatting for display.
  final DateTime recordedAt;

  /// 'on_time' / 'late' / 'early_leave' / 'overtime', or null when the
  /// staff member has no assigned shift to compare against.
  final String? status;

  final String? photoUrl;
  final String staffFullName;
  final String staffCode;
  final String? shiftName;

  bool get isCheckIn => type == 'check_in';
}
