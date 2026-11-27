import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../staff/data/shift_api_service.dart';
import '../staff/data/shift_model.dart';
import 'create_edit_shift_screen.dart';
import 'shift_staff_dialogs.dart';

enum _SortOption { startTime, name, staffAssigned }

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _shiftApiService = const ShiftApiService();
  final _searchController = TextEditingController();

  List<Shift> _shifts = [];
  bool _isLoading = true;
  String? _loadError;

  String _statusTab = 'All';
  _SortOption _sortOption = _SortOption.startTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final shifts = await _shiftApiService.getShifts();
      if (!mounted) return;
      setState(() {
        _shifts = shifts;
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
        _loadError = 'Could not load shifts. Please try again.';
      });
    }
  }

  List<Shift> get _visibleShifts {
    final query = _searchController.text.trim().toLowerCase();

    var result = _shifts.where((shift) {
      final matchesSearch =
          query.isEmpty || shift.name.toLowerCase().contains(query);
      final matchesTab =
          _statusTab == 'All' ||
          (_statusTab == 'Active' && shift.isActive) ||
          (_statusTab == 'Inactive' && !shift.isActive);
      return matchesSearch && matchesTab;
    }).toList();

    result.sort((a, b) {
      switch (_sortOption) {
        case _SortOption.startTime:
          return a.startTime.compareTo(b.startTime);
        case _SortOption.name:
          return a.name.compareTo(b.name);
        case _SortOption.staffAssigned:
          return (b.staffCount ?? 0).compareTo(a.staffCount ?? 0);
      }
    });

    return result;
  }

  Future<void> _goToCreateShift() async {
    final created = await NavigationUtils.push<bool>(
      const CreateEditShiftScreen(),
      context: context,
    );
    if (created == true) _load();
  }

  Future<void> _goToEditShift(Shift shift) async {
    final updated = await NavigationUtils.push<bool>(
      CreateEditShiftScreen(shift: shift),
      context: context,
    );
    if (updated == true) _load();
  }

  Future<void> _toggleStatus(Shift shift) async {
    try {
      await _shiftApiService.changeShiftStatus(
        shiftId: shift.id,
        status: shift.isActive ? 'inactive' : 'active',
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    }
  }

  Future<void> _deleteShift(Shift shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shift'),
        content: Text(
          'Are you sure you want to delete "${shift.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _shiftApiService.deleteShift(shift.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    }
  }

  Future<void> _openAssignDialog(Shift shift) async {
    final assigned = await showDialog<bool>(
      context: context,
      builder: (context) => AssignStaffToShiftDialog(shift: shift),
    );
    if (assigned == true) _load();
  }

  Future<void> _openManageDialog(Shift shift) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => ManageShiftStaffDialog(shift: shift),
    );
    if (changed == true) _load();
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
    final total = _shifts.length;
    final active = _shifts.where((s) => s.isActive).length;
    final inactive = total - active;

    final cards = [
      _StatCard(
        label: 'TOTAL SHIFT TEMPLATES',
        value: '$total',
        caption: 'Reusable Templates',
        icon: Icons.calendar_month_outlined,
        iconBackground: AppColors.surfaceHighlight,
        iconColor: AppColors.primary,
      ),
      _StatCard(
        label: 'ACTIVE SHIFTS',
        value: '$active',
        caption: 'Currently Rostered',
        icon: Icons.check_circle_outline,
        iconBackground: AppColors.onDutyBackground,
        iconColor: AppColors.onDutyText,
      ),
      _StatCard(
        label: 'INACTIVE SHIFTS',
        value: '$inactive',
        caption: 'Archived / Standby',
        icon: Icons.pause_circle_outline,
        iconBackground: AppColors.offDutyBackground,
        iconColor: AppColors.offDutyText,
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

  Widget _buildToolbar(BuildContext context) {
    final total = _shifts.length;
    final active = _shifts.where((s) => s.isActive).length;
    final inactive = total - active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'Search shifts by name...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: _goToCreateShift,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Shift'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabChip(
                      label: 'All ($total)',
                      selected: _statusTab == 'All',
                      onTap: () => setState(() => _statusTab = 'All'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TabChip(
                      label: 'Active ($active)',
                      selected: _statusTab == 'Active',
                      onTap: () => setState(() => _statusTab = 'Active'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TabChip(
                      label: 'Inactive ($inactive)',
                      selected: _statusTab == 'Inactive',
                      onTap: () => setState(() => _statusTab = 'Inactive'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButtonHideUnderline(
              child: DropdownButton<_SortOption>(
                value: _sortOption,
                borderRadius: BorderRadius.circular(AppRadius.base),
                items: const [
                  DropdownMenuItem(
                    value: _SortOption.startTime,
                    child: Text('Start Time'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.name,
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.staffAssigned,
                    child: Text('Staff Assigned'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sortOption = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _shifts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null && _shifts.isEmpty) {
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

    final visible = _visibleShifts;

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _shifts.isEmpty ? 'No shift templates yet' : 'No matching shifts',
              style: AppTypography.headlineSm(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _shifts.isEmpty
                  ? 'Create your first shift template to start rostering staff.'
                  : 'Try a different search term or filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(color: AppColors.textSecondary),
            ),
            if (_shifts.isEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _goToCreateShift,
                icon: const Icon(Icons.add),
                label: const Text('Add Shift'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final shift in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ShiftCard(
              shift: shift,
              onEdit: () => _goToEditShift(shift),
              onToggleStatus: () => _toggleStatus(shift),
              onDelete: () => _deleteShift(shift),
              onAssign: () => _openAssignDialog(shift),
              onManage: () => _openManageDialog(shift),
            ),
          ),
      ],
    );
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

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLg(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.shift,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onAssign,
    required this.onManage,
  });

  final Shift shift;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onAssign;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          shift.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMd(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (shift.shiftType != null &&
                            shift.shiftType!.isNotEmpty)
                          _Pill(
                            label: shift.shiftType!,
                            background: AppColors.secondaryButtonBackground,
                            border: AppColors.secondaryButtonBorder,
                            textColor: AppColors.secondaryButtonText,
                          ),
                      ],
                    ),
                    if (shift.description != null &&
                        shift.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        shift.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _statusChip(shift.isActive),
              const SizedBox(width: AppSpacing.xs),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                onSelected: (value) {
                  if (value == 'toggle') onToggleStatus();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(shift.isActive ? 'Deactivate' : 'Activate'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${DateTimeUtils.formatTime24(shift.startTime)} – '
                    '${DateTimeUtils.formatTime24(shift.endTime)}',
                    style: AppTypography.labelLg(color: AppColors.textPrimary),
                  ),
                ),
                if (shift.durationHours != null)
                  _Pill(
                    label: '${shift.durationHours} hrs',
                    background: AppColors.surfaceCard,
                    border: AppColors.border,
                    textColor: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'BREAK DURATION',
                  value: '${shift.breakDurationMinutes} mins',
                  icon: Icons.free_breakfast_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: 'GRACE PERIOD',
                  value: '${shift.gracePeriodMinutes} mins tolerance',
                  icon: Icons.hourglass_bottom,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'SCHEDULED DAYS',
            style: AppTypography.labelSm(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (var i = 0; i < Shift.weekdays.length; i++) ...[
                _DayBadge(
                  label: Shift.weekdays[i][0],
                  active: shift.scheduledDays.contains(Shift.weekdays[i]),
                ),
                if (i != Shift.weekdays.length - 1)
                  const SizedBox(width: AppSpacing.xs),
              ],
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  shift.scheduledDaysLabel,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodySm(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shift.staffCount ?? shift.assignedStaff.length} Staff Assigned',
                        style: AppTypography.labelLg(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (shift.assignedStaff.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: _AvatarStack(staff: shift.assignedStaff),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(onPressed: onManage, child: const Text('Manage')),
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Assign'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Shift'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    final background = isActive
        ? AppColors.onDutyBackground
        : AppColors.offDutyBackground;
    final border = isActive ? AppColors.onDutyBorder : AppColors.offDutyBorder;
    final text = isActive ? AppColors.onDutyText : AppColors.offDutyText;
    final dot = isActive ? AppColors.onDutyDot : AppColors.offDutyDot;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: AppTypography.labelSm(color: text),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.border,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border),
      ),
      child: Text(label, style: AppTypography.labelSm(color: textColor)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.base),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSm(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.labelLg(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.base),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm(
          color: active ? AppColors.onPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.staff});

  final List<ShiftStaffBrief> staff;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    const overlap = 32.0;
    final shown = staff.take(5).toList();

    return SizedBox(
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceCard, width: 2),
                ),
                child: Text(
                  _initialsFor(shown[i].fullName),
                  style: AppTypography.labelMd(color: AppColors.onPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initialsFor(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).take(2);
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }
}
