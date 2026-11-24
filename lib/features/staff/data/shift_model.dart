class ShiftStaffBrief {
  const ShiftStaffBrief({required this.id, required this.fullName});

  factory ShiftStaffBrief.fromJson(Map<String, dynamic> json) {
    return ShiftStaffBrief(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
    );
  }

  final int id;
  final String fullName;
}

class Shift {
  const Shift({
    required this.id,
    required this.name,
    this.shiftType,
    this.description,
    required this.startTime,
    required this.endTime,
    this.durationHours,
    this.status = 'active',
    this.breakDurationMinutes = 15,
    this.gracePeriodMinutes = 10,
    this.scheduledDays = const [],
    this.staffCount,
    this.assignedStaff = const [],
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as int,
      name: json['name'] as String,
      shiftType: json['shift_type'] as String?,
      description: json['description'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      breakDurationMinutes: json['break_duration_minutes'] as int? ?? 15,
      gracePeriodMinutes: json['grace_period_minutes'] as int? ?? 10,
      scheduledDays:
          (json['scheduled_days'] as List?)
              ?.map((day) => day as String)
              .toList() ??
          const [],
      staffCount: json['staff_count'] as int?,
      assignedStaff:
          (json['assigned_staff'] as List?)
              ?.map(
                (staff) =>
                    ShiftStaffBrief.fromJson(staff as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  final int id;
  final String name;
  final String? shiftType;
  final String? description;
  final String startTime;
  final String endTime;
  final double? durationHours;
  final String status;
  final int breakDurationMinutes;
  final int gracePeriodMinutes;
  final List<String> scheduledDays;
  final int? staffCount;
  final List<ShiftStaffBrief> assignedStaff;

  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool get isActive => status == 'active';

  String get label => '$name ($startTime – $endTime)';

  bool get isDaily => scheduledDays.length == 7;

  String get scheduledDaysLabel {
    if (isDaily) return 'Daily (7 days)';
    if (scheduledDays.isEmpty) return 'No days scheduled';
    return scheduledDays.join(', ');
  }
}
