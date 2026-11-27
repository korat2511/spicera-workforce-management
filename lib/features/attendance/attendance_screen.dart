import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../staff/data/staff_api_service.dart';
import '../staff/data/staff_model.dart';
import 'data/attendance_api_service.dart';
import 'data/attendance_record_model.dart';

const int _rosterStaffFlex = 40;
const int _rosterTimeFlex = 22;
const int _rosterStatusFlex = 22;
const int _rosterActionFlex = 15;
const double _rosterMidGap = AppSpacing.md;

const int _dateSwiperDays = 21;

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

(int, int) _parseHm(String hm) {
  final parts = hm.split(':');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

DateTime _scheduledStartOn(DateTime anchor, String startHm) {
  final (hour, minute) = _parseHm(startHm);
  return DateTime(anchor.year, anchor.month, anchor.day, hour, minute);
}

DateTime _scheduledEndOn(DateTime anchor, String startHm, String endHm) {
  final start = _scheduledStartOn(anchor, startHm);
  final (hour, minute) = _parseHm(endHm);
  var end = DateTime(anchor.year, anchor.month, anchor.day, hour, minute);
  if (!end.isAfter(start)) {
    end = end.add(const Duration(days: 1));
  }
  return end;
}

String _formatDuration(Duration duration) {
  final hours = duration.inMinutes ~/ 60;
  final minutes = duration.inMinutes % 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _apiService = const AttendanceApiService();
  final _staffApiService = const StaffApiService();
  final _searchController = TextEditingController();
  final _dateScrollController = ScrollController();

  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String? _loadError;

  List<Staff> _activeStaff = [];
  bool _isLoadingStaff = true;

  DateTime _selectedDate = _dateOnly(DateTime.now());
  String? _statusFilter;

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        _dateScrollController.jumpTo(
          _dateScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final page = await _staffApiService.getStaffList(
        status: 'active',
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _activeStaff = page.items;
        _isLoadingStaff = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final searching = _isSearching;
    try {
      final records = await _apiService.list(
        search: searching ? _searchController.text.trim() : null,
        status: searching ? _statusFilter : null,
        dateFrom: searching ? null : _selectedDate,
        dateTo: searching ? null : _selectedDate,
      );
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load attendance records. Please try again.';
      });
    }
  }

  AttendanceRecord? _findRecord(String staffCode, bool isCheckIn) {
    for (final record in _records) {
      if (record.staffCode == staffCode && record.isCheckIn == isCheckIn) {
        return record;
      }
    }
    return null;
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _dateOnly(DateTime.now()),
      initialDate: _selectedDate,
    );
    if (picked == null) return;
    _selectDate(_dateOnly(picked));
  }

  void _viewPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding:
                ResponsiveUtils.screenPadding(context) +
                const EdgeInsets.only(top: AppSpacing.md),
            child: _buildStatsRow(context),
          ),
          Padding(
            padding:
                ResponsiveUtils.screenPadding(context) +
                const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: _buildToolbar(context),
          ),
          Padding(
            padding:
                ResponsiveUtils.screenPadding(context) +
                const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final total = _records.length;
    final checkedIn = _records.where((r) => r.isCheckIn).length;
    final late = _records.where((r) => r.status == 'late').length;

    final cards = [
      _StatCard(
        label: 'TOTAL PUNCHES',
        value: '$total',
        caption: _statsCaption,
        icon: Icons.fingerprint,
        iconBackground: AppColors.surfaceHighlight,
        iconColor: AppColors.primary,
      ),
      _StatCard(
        label: 'CHECKED IN',
        value: '$checkedIn',
        caption: 'Check-ins recorded',
        icon: Icons.login,
        iconBackground: AppColors.onDutyBackground,
        iconColor: AppColors.onDutyText,
      ),
      _StatCard(
        label: 'LATE',
        value: '$late',
        caption: 'Late arrivals',
        icon: Icons.schedule,
        iconBackground: AppColors.breakBackground,
        iconColor: AppColors.breakText,
      ),
    ];

    if (ResponsiveUtils.isMobile(context)) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }

  String get _statsCaption {
    if (_isSearching) return 'All matching records';
    return _dateHeaderLabel(_selectedDate);
  }

  Widget _buildToolbar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                  _load();
                },
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'Search by staff name or code...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _statusFilter,
                borderRadius: BorderRadius.circular(AppRadius.base),
                hint: const Text('All Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'on_time', child: Text('On Time')),
                  DropdownMenuItem(value: 'late', child: Text('Late')),
                  DropdownMenuItem(
                    value: 'early_leave',
                    child: Text('Early Leave'),
                  ),
                  DropdownMenuItem(
                    value: 'overtime',
                    child: Text('Overtime'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                  _load();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isSearching)
          Text(
            'Showing matches across all dates',
            style: AppTypography.bodySm(color: AppColors.textMuted),
          )
        else
          _buildDateSwiper(context),
      ],
    );
  }

  Widget _buildDateSwiper(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(
      _dateSwiperDays,
      (i) => today.subtract(Duration(days: _dateSwiperDays - 1 - i)),
    );

    return Row(
      children: [
        IconButton(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month, color: AppColors.primary),
        ),
        Expanded(
          child: SizedBox(
            height: 92,
            child: ListView.separated(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final date = days[index];
                return _DateChip(
                  date: date,
                  selected: _isSameDay(date, _selectedDate),
                  onTap: () => _selectDate(date),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if ((_isLoading && _records.isEmpty) ||
        (!_isSearching && _isLoadingStaff)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null && _records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (!_isSearching) {
      return _buildRoster(context);
    }

    return _buildSearchResults(context);
  }

  Widget _buildRoster(BuildContext context) {
    var rows = _activeStaff
        .map(
          (staff) => _RosterRow(
            staff: staff,
            checkIn: _findRecord(staff.staffCode, true),
            checkOut: _findRecord(staff.staffCode, false),
          ),
        )
        .toList();

    if (_statusFilter != null) {
      rows = rows.where((row) => row.status == _statusFilter).toList();
    }

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.person_search_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No staff match this filter',
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm(color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    return _RosterTable(rows: rows, onViewPhoto: _viewPhoto);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.person_search_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No attendance records found',
              style: AppTypography.headlineSm(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search term or filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<AttendanceRecord>>{};
    for (final record in _records) {
      final label = _dateHeaderLabel(record.recordedAt.toLocal());
      grouped.putIfAbsent(label, () => []).add(record);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              entry.key,
              style: AppTypography.labelLg(color: AppColors.textMuted),
            ),
          ),
          for (final record in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _AttendanceCard(
                record: record,
                onViewPhoto: _viewPhoto,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  String _dateHeaderLabel(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final d = _dateOnly(date);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateTimeUtils.formatApiDate(DateTimeUtils.toApiDate(d));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSm(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTypography.displayLgMobile(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  caption,
                  style: AppTypography.bodySm(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, _dateOnly(DateTime.now()));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isToday ? 'TODAY' : DateTimeUtils.formatWeekdayShort(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd(
                color: selected ? AppColors.onPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: AppTypography.headlineSm(
                color: selected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record, required this.onViewPhoto});

  final AttendanceRecord record;
  final ValueChanged<String> onViewPhoto;

  String _initialsFor(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).take(2);
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      record.staffCode,
      if (record.shiftName != null) record.shiftName!,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initialsFor(record.staffFullName),
              style: AppTypography.labelSm(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.staffFullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd(color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _TypeBadge(isCheckIn: record.isCheckIn),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 60,
            child: Text(
              DateTimeUtils.formatTime(record.recordedAt.toLocal()),
              textAlign: TextAlign.right,
              style: AppTypography.labelSm(color: AppColors.textSecondary),
            ),
          ),
          if (record.status != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _StatusChip(status: record.status!),
          ],
          if (record.photoUrl != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: () => onViewPhoto(record.photoUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.base),
                child: Image.network(
                  record.photoUrl!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 28,
                    height: 28,
                    color: AppColors.surfaceInput,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isCheckIn});

  final bool isCheckIn;

  @override
  Widget build(BuildContext context) {
    return Icon(
      isCheckIn ? Icons.login : Icons.logout,
      size: 16,
      color: isCheckIn ? AppColors.onDutyText : AppColors.offDutyText,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.duration});

  final String status;
  final String? duration;

  @override
  Widget build(BuildContext context) {
    final (label, background, textColor) = switch (status) {
      'late' => ('Late', AppColors.breakBackground, AppColors.breakText),
      'early_leave' => (
        'Early Leave',
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
      'overtime' => (
        'Overtime',
        AppColors.secondaryButtonBackground,
        AppColors.secondaryButtonText,
      ),
      'not_checked_in' => (
        'Not Checked In',
        AppColors.offDutyBackground,
        AppColors.offDutyText,
      ),
      'currently_working' => (
        'Currently Working',
        AppColors.onDutyBackground,
        AppColors.onDutyText,
      ),
      _ => ('On Time', AppColors.onDutyBackground, AppColors.onDutyText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        duration == null ? label : '$label · $duration',
        textAlign: TextAlign.center,
        style: AppTypography.labelSm(color: textColor),
      ),
    );
  }
}

class _RosterRow {
  const _RosterRow({required this.staff, this.checkIn, this.checkOut});

  final Staff staff;
  final AttendanceRecord? checkIn;
  final AttendanceRecord? checkOut;

  String get status {
    if (checkIn == null) return 'not_checked_in';
    if (checkIn!.status == 'late') return 'late';
    if (checkOut == null) return 'currently_working';
    if (checkOut!.status == 'early_leave') return 'early_leave';
    if (checkOut!.status == 'overtime') return 'overtime';
    return 'on_time';
  }

  /// How late/early/over the staff member is, e.g. "15m" or "1h 20m".
  /// Null when the status doesn't carry a duration or the staff member
  /// has no assigned shift to measure against.
  String? get durationLabel {
    final shift = staff.shift;
    if (shift == null) return null;

    switch (status) {
      case 'late':
        final checkInLocal = checkIn!.recordedAt.toLocal();
        final scheduledStart = _scheduledStartOn(checkInLocal, shift.startTime);
        final diff = checkInLocal.difference(scheduledStart);
        return diff.inMinutes > 0 ? _formatDuration(diff) : null;
      case 'early_leave':
      case 'overtime':
        final checkOutLocal = checkOut!.recordedAt.toLocal();
        final anchor = checkIn?.recordedAt.toLocal() ?? checkOutLocal;
        final scheduledEnd = _scheduledEndOn(anchor, shift.startTime, shift.endTime);
        final diff = status == 'overtime'
            ? checkOutLocal.difference(scheduledEnd)
            : scheduledEnd.difference(checkOutLocal);
        return diff.inMinutes > 0 ? _formatDuration(diff) : null;
      default:
        return null;
    }
  }
}

class _RosterTable extends StatelessWidget {
  const _RosterTable({required this.rows, required this.onViewPhoto});

  final List<_RosterRow> rows;
  final ValueChanged<String> onViewPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
          for (var i = 0; i < rows.length; i++)
            _RosterTableRow(
              row: rows[i],
              isLast: i == rows.length - 1,
              onViewPhoto: onViewPhoto,
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final style = AppTypography.labelSm(color: AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceInput,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _rosterStaffFlex,
            child: Text('STAFF MEMBER', style: style),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: _rosterTimeFlex,
            child: Text(
              'CHECK IN',
              textAlign: TextAlign.center,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _rosterMidGap),
          Expanded(
            flex: _rosterTimeFlex,
            child: Text(
              'CHECK OUT',
              textAlign: TextAlign.center,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _rosterMidGap),
          Expanded(
            flex: _rosterStatusFlex,
            child: Text(
              'STATUS',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: _rosterActionFlex,
            child: Text(
              'PHOTO',
              textAlign: TextAlign.center,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterTableRow extends StatelessWidget {
  const _RosterTableRow({
    required this.row,
    required this.isLast,
    required this.onViewPhoto,
  });

  final _RosterRow row;
  final bool isLast;
  final ValueChanged<String> onViewPhoto;

  String _initialsFor(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).take(2);
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final staff = row.staff;
    final photoUrl = row.checkOut?.photoUrl ?? row.checkIn?.photoUrl;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _rosterStaffFlex,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _initialsFor(staff.fullName),
                    style: AppTypography.labelMd(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        staff.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        staff.staffCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: _rosterTimeFlex,
            child: Center(
              child: row.checkIn == null
                  ? Text(
                      '—',
                      style: AppTypography.bodyMd(color: AppColors.textMuted),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateTimeUtils.formatTime(
                            row.checkIn!.recordedAt.toLocal(),
                          ),
                          style: AppTypography.labelLg(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.onDutyText,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: _rosterMidGap),
          Expanded(
            flex: _rosterTimeFlex,
            child: Center(
              child: Text(
                row.checkOut == null
                    ? '—'
                    : DateTimeUtils.formatTime(
                        row.checkOut!.recordedAt.toLocal(),
                      ),
                style: AppTypography.labelLg(
                  color: row.checkOut == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: _rosterMidGap),
          Expanded(
            flex: _rosterStatusFlex,
            child: Center(
              child: _StatusChip(
                status: row.status,
                duration: row.durationLabel,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: _rosterActionFlex,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: photoUrl == null
                      ? AppColors.textMuted
                      : AppColors.primary,
                ),
                onPressed: photoUrl == null
                    ? null
                    : () => onViewPhoto(photoUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
