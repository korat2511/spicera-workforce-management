import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_time_utils.dart';
import '../attendance/data/attendance_api_service.dart';
import '../attendance/data/attendance_record_model.dart';
import 'data/staff_model.dart';

enum _DayStatus { present, absent, autoCheckout, future }

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Embeddable monthly present/absent calendar for a single staff member.
/// Meant to be dropped at the bottom of a section card, not pushed as its
/// own screen.
class StaffAttendanceCalendar extends StatefulWidget {
  const StaffAttendanceCalendar({super.key, required this.staff});

  final Staff staff;

  @override
  State<StaffAttendanceCalendar> createState() =>
      _StaffAttendanceCalendarState();
}

class _StaffAttendanceCalendarState extends State<StaffAttendanceCalendar> {
  final _apiService = const AttendanceApiService();

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isFirstLoad = _isLoading;
    setState(() {
      if (!isFirstLoad) _isRefreshing = true;
      _error = null;
    });

    final from = DateTime(_month.year, _month.month, 1);
    final to = DateTime(_month.year, _month.month + 1, 0);

    try {
      final records = await _apiService.list(
        staffId: widget.staff.id,
        dateFrom: from,
        dateTo: to,
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = 'Could not load attendance. Please try again.';
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  _DayStatus _statusFor(DateTime day) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (day.isAfter(todayOnly)) return _DayStatus.future;

    var hasCheckIn = false;
    var hasCheckOut = false;
    for (final record in _records) {
      final local = record.recordedAt.toLocal();
      if (local.year != day.year ||
          local.month != day.month ||
          local.day != day.day) {
        continue;
      }
      if (record.isCheckIn) {
        hasCheckIn = true;
      } else {
        hasCheckOut = true;
      }
    }

    if (hasCheckIn && hasCheckOut) return _DayStatus.present;
    if (hasCheckIn && !hasCheckOut) return _DayStatus.autoCheckout;
    return _DayStatus.absent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthHeader(),
        const SizedBox(height: AppSpacing.md),
        _buildLegend(),
        const SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _buildGrid(),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Column(
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateTimeUtils.formatMonthYear(_month),
              style: AppTypography.titleMd(color: AppColors.textPrimary),
            ),
            if (_isRefreshing) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final items = [
      ('Present', AppColors.onDutyDot),
      ('Absent', AppColors.error),
      ('Auto Checkout', AppColors.breakDot),
      ('Future', AppColors.offDutyDot),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTypography.labelSm(color: AppColors.textMuted)),
            ],
          ),
      ],
    );
  }

  Widget _buildGrid() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7;
    final weeksNeeded = ((leadingBlanks + daysInMonth) / 7).ceil();
    final totalCells = weeksNeeded * 7;

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTypography.labelSm(color: AppColors.textMuted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final day = DateTime(_month.year, _month.month, dayNumber);
            final isToday = day == todayOnly;
            final status = _statusFor(day);

            final (background, foreground) = isToday
                ? (AppColors.tertiary, AppColors.onTertiary)
                : switch (status) {
                    _DayStatus.present => (
                      AppColors.onDutyDot,
                      AppColors.onPrimary,
                    ),
                    _DayStatus.absent => (AppColors.error, AppColors.onError),
                    _DayStatus.autoCheckout => (
                      AppColors.breakDot,
                      AppColors.onPrimary,
                    ),
                    _DayStatus.future => (
                      AppColors.surfaceInput,
                      AppColors.textMuted,
                    ),
                  };

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.base),
              ),
              child: Text(
                '$dayNumber',
                style: AppTypography.labelMd(color: foreground),
              ),
            );
          },
        ),
      ],
    );
  }
}
