import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../../shared_widgets/app_section_card.dart';
import 'data/shift_api_service.dart';
import 'data/shift_model.dart';
import 'data/staff_api_service.dart';
import 'data/staff_model.dart';
import 'edit_staff_screen.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key, required this.staff});

  final Staff staff;

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _staffApiService = const StaffApiService();
  late Staff _staff = widget.staff;
  bool _isTogglingStatus = false;
  bool _isUpdatingShift = false;

  Future<void> _toggleStatus() async {
    final nextStatus = _staff.status == 'active' ? 'inactive' : 'active';
    setState(() => _isTogglingStatus = true);

    try {
      final updated = await _staffApiService.changeStatus(
        staffId: _staff.id,
        status: nextStatus,
      );
      if (!mounted) return;
      setState(() {
        _staff = updated;
        _isTogglingStatus = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingStatus = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTogglingStatus = false);
      SnackbarUtils.showError(context, 'Could not update status.');
    }
  }

  Future<void> _openAssignShiftDialog() async {
    final result = await showDialog<_ShiftSelection>(
      context: context,
      builder: (context) => _AssignShiftDialog(currentShift: _staff.shift),
    );

    if (result == null) return;

    setState(() => _isUpdatingShift = true);

    try {
      final updated = await _staffApiService.assignShift(
        staffId: _staff.id,
        shiftId: result.shiftId,
      );
      if (!mounted) return;
      setState(() {
        _staff = updated;
        _isUpdatingShift = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingShift = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingShift = false);
      SnackbarUtils.showError(context, 'Could not update shift.');
    }
  }

  void _pinActionComingSoon() {
    SnackbarUtils.showInfo(context, 'PIN management coming soon');
  }

  Future<void> _goToEditStaff() async {
    final updated = await NavigationUtils.push<Staff>(
      EditStaffScreen(staff: _staff),
      context: context,
    );
    if (updated == null || !mounted) return;
    setState(() => _staff = updated);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _staff.status == 'active';

    final contactCard = AppSectionCard(
      letter: 'A',
      title: 'Contact Details',
      subtitle: 'Phone & email',
      children: [
        _InfoRows(
          rows: [
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _staff.phone,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _staff.email != null && _staff.email!.isNotEmpty
                  ? _staff.email!
                  : 'Not provided',
              valueColor: _staff.email != null && _staff.email!.isNotEmpty
                  ? null
                  : AppColors.textMuted,
            ),
          ],
        ),
      ],
    );

    final employmentCard = AppSectionCard(
      letter: 'B',
      title: 'Employment Details',
      subtitle: 'Role & dates',
      children: [
        _InfoRows(
          rows: [
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Employment Type',
              value: _staff.employmentType,
            ),
            if (_staff.jobTitle != null && _staff.jobTitle!.isNotEmpty)
              _InfoRow(
                icon: Icons.work_outline,
                label: 'Job Title',
                value: _staff.jobTitle!,
              ),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Joining Date',
              value: DateTimeUtils.formatApiDate(_staff.joiningDate),
            ),
            _InfoRow(
              icon: isActive
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              label: 'Status',
              value: isActive ? 'Active' : 'Inactive',
              trailing: TextButton(
                onPressed: _isTogglingStatus ? null : _toggleStatus,
                child: _isTogglingStatus
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isActive ? 'Mark as Inactive' : 'Mark as Active'),
              ),
            ),
          ],
        ),
      ],
    );

    final compensationCard = AppSectionCard(
      letter: 'C',
      title: 'Compensation',
      subtitle: 'Payroll & wages',
      children: [
        _InfoRows(
          rows: [
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Salary Rate',
              value:
                  '\$${_staff.salaryRate} ${_staff.currency} / '
                  '${_staff.salaryType.toLowerCase()}',
            ),
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Overtime Pay',
              value: _staff.overtimeLabel,
              valueColor: _staff.overtimeRateType == 'not_eligible'
                  ? AppColors.textMuted
                  : null,
            ),
          ],
        ),
      ],
    );

    final shiftCard = AppSectionCard(
      letter: 'D',
      title: 'Shift & Attendance',
      subtitle: 'Scheduling & PIN access',
      children: [
        _InfoRows(
          rows: [
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Assigned Shift',
              value: _staff.shift?.label ?? 'Not assigned',
              trailing: TextButton.icon(
                onPressed: _isUpdatingShift ? null : _openAssignShiftDialog,
                icon: _isUpdatingShift
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_calendar_outlined, size: 16),
                label: const Text('Assign'),
              ),
            ),
            _InfoRow(
              icon: _staff.pinSet
                  ? Icons.lock_outline
                  : Icons.lock_open_outlined,
              label: 'Attendance PIN',
              value: _staff.pinSet ? '••••••' : 'Not set',
              valueColor: _staff.pinSet ? AppColors.onDutyText : AppColors.error,
              trailing: _staff.pinSet
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _pinActionComingSoon,
                          child: const Text('Reset PIN'),
                        ),
                        TextButton(
                          onPressed: _pinActionComingSoon,
                          child: const Text('Change PIN'),
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: _pinActionComingSoon,
                      child: const Text('Set PIN'),
                    ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Profile'),
        actions: [
          IconButton(
            onPressed: _goToEditStaff,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Staff',
          ),
        ],
      ),
      body: ListView(
        padding:
            ResponsiveUtils.screenPadding(context) +
            const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          if (ResponsiveUtils.isMobile(context)) ...[
            _ProfileHeader(staff: _staff, isActive: isActive),
            const SizedBox(height: AppSpacing.lg),
            contactCard,
          ] else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ProfileHeader(staff: _staff, isActive: isActive),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: contactCard),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          employmentCard,
          const SizedBox(height: AppSpacing.lg),
          compensationCard,
          const SizedBox(height: AppSpacing.lg),
          shiftCard,
        ],
      ),
    );
  }
}

class _ShiftSelection {
  const _ShiftSelection(this.shiftId);

  final int? shiftId;
}

class _AssignShiftDialog extends StatefulWidget {
  const _AssignShiftDialog({required this.currentShift});

  final Shift? currentShift;

  @override
  State<_AssignShiftDialog> createState() => _AssignShiftDialogState();
}

class _AssignShiftDialogState extends State<_AssignShiftDialog> {
  final _shiftApiService = const ShiftApiService();

  List<Shift> _shifts = [];
  bool _isLoading = true;
  String? _loadError;
  int? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _selectedShiftId = widget.currentShift?.id;
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Shift',
                style: AppTypography.headlineSm(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Flexible(child: _buildBody()),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(_ShiftSelection(_selectedShiftId)),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RadioGroup<int?>(
      groupValue: _selectedShiftId,
      onChanged: (value) => setState(() => _selectedShiftId = value),
      child: ListView(
        shrinkWrap: true,
        children: [
          RadioListTile<int?>(
            contentPadding: EdgeInsets.zero,
            value: null,
            title: Text(
              'Unassigned',
              style: AppTypography.bodyLg(color: AppColors.textPrimary),
            ),
          ),
          for (final shift in _shifts)
            RadioListTile<int?>(
              contentPadding: EdgeInsets.zero,
              value: shift.id,
              title: Text(
                shift.name,
                style: AppTypography.bodyLg(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                '${shift.startTime} – ${shift.endTime}',
                style: AppTypography.bodySm(color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.staff, required this.isActive});

  final Staff staff;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(staff.fullName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: staff.profilePhotoUrl == null
                ? Text(
                    initials,
                    style: AppTypography.displayLgMobile(
                      color: AppColors.primary,
                    ),
                  )
                : Image.network(
                    staff.profilePhotoUrl!,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Text(
                      initials,
                      style: AppTypography.displayLgMobile(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            staff.fullName,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Text(
                  staff.staffCode,
                  style: AppTypography.labelSm(color: AppColors.textSecondary),
                ),
              ),
              if (staff.jobTitle != null && staff.jobTitle!.isNotEmpty)
                Text(
                  staff.jobTitle!,
                  style: AppTypography.bodyMd(color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statusChip(isActive),
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

  String _initialsFor(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).take(2);
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }
}

class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: AppTypography.bodyMd(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyLg(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
