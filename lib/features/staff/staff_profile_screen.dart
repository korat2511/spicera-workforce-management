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
import '../../shared_widgets/pin_keypad.dart';
import 'data/shift_api_service.dart';
import 'data/shift_model.dart';
import 'data/staff_api_service.dart';
import 'data/staff_model.dart';
import 'edit_staff_screen.dart';
import 'staff_attendance_calendar_screen.dart';

/// Hardcoded admin verification PIN, gating PIN reset/change. Temporary —
/// will move to a real per-business admin credential later.
const _masterPin = '251120';

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
  bool _isUpdatingPin = false;

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

  Future<void> _handleResetPin() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _PinWizardDialog(
        steps: [
          _PinWizardStep(
            title: 'Admin Verification',
            subtitle: 'Enter the admin PIN to continue.',
            validate: (value, collected) =>
                value == _masterPin ? null : 'Incorrect admin PIN',
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: Text(
          "This clears ${_staff.fullName}'s attendance PIN. They won't be "
          'able to mark attendance until a new PIN is set.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUpdatingPin = true);
    try {
      final updated = await _staffApiService.setPin(staffId: _staff.id);
      if (!mounted) return;
      setState(() {
        _staff = updated;
        _isUpdatingPin = false;
      });
      SnackbarUtils.showSuccess(context, 'PIN has been reset');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPin = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingPin = false);
      SnackbarUtils.showError(context, 'Could not reset PIN.');
    }
  }

  Future<void> _handleChangePin() async {
    final hasExistingPin = _staff.pinSet;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _PinWizardDialog(
        steps: [
          if (hasExistingPin)
            _PinWizardStep(
              title: 'Enter Current PIN',
              subtitle: "Enter ${_staff.fullName}'s current PIN.",
              asyncValidate: (value, collected) async {
                try {
                  final matches = await _staffApiService.verifyPin(
                    staffId: _staff.id,
                    pin: value,
                  );
                  return matches ? null : 'The current PIN is incorrect.';
                } on ApiException catch (e) {
                  return e.message;
                } catch (_) {
                  return 'Could not verify the PIN. Please try again.';
                }
              },
            ),
          const _PinWizardStep(
            title: 'Enter New PIN',
            subtitle: 'Choose a new 6-digit PIN.',
          ),
          _PinWizardStep(
            title: 'Confirm New PIN',
            subtitle: 'Re-enter the new PIN to confirm.',
            validate: (value, collected) =>
                value == collected.last ? null : 'PINs do not match',
          ),
          _PinWizardStep(
            title: 'Admin Verification',
            subtitle: 'Enter the admin PIN to continue.',
            validate: (value, collected) =>
                value == _masterPin ? null : 'Incorrect admin PIN',
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    final currentPin = hasExistingPin ? result[0] : null;
    final newPin = hasExistingPin ? result[1] : result[0];
    final confirmPin = hasExistingPin ? result[2] : result[1];

    setState(() => _isUpdatingPin = true);
    try {
      final updated = await _staffApiService.setPin(
        staffId: _staff.id,
        pin: newPin,
        pinConfirmation: confirmPin,
        currentPin: currentPin,
      );
      if (!mounted) return;
      setState(() {
        _staff = updated;
        _isUpdatingPin = false;
      });
      SnackbarUtils.showSuccess(context, 'PIN updated successfully');
    } on ApiValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPin = false);
      SnackbarUtils.showError(context, e.firstMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPin = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingPin = false);
      SnackbarUtils.showError(context, 'Could not update PIN.');
    }
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
                          onPressed: _isUpdatingPin ? null : _handleResetPin,
                          child: const Text('Reset PIN'),
                        ),
                        TextButton(
                          onPressed: _isUpdatingPin ? null : _handleChangePin,
                          child: const Text('Change PIN'),
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: _isUpdatingPin ? null : _handleChangePin,
                      child: const Text('Set PIN'),
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.lg),
        StaffAttendanceCalendar(staff: _staff),
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

class _PinWizardStep {
  const _PinWizardStep({
    required this.title,
    this.subtitle,
    this.validate,
    this.asyncValidate,
  });

  final String title;
  final String? subtitle;

  /// Validates the entered PIN before the wizard advances. [collected]
  /// holds every prior step's value in order, letting a step (e.g.
  /// "Confirm New PIN") check itself against an earlier answer.
  final String? Function(String value, List<String> collected)? validate;

  /// Like [validate], but for checks that need a server round-trip (e.g.
  /// verifying a staff member's current PIN). Runs after [validate] passes.
  final Future<String?> Function(String value, List<String> collected)?
  asyncValidate;
}

/// Single-keypad, step-by-step PIN entry dialog shared by the reset/change
/// PIN flows. Pops a `List<String>` of each step's entered value in order,
/// or null if cancelled from the first step.
class _PinWizardDialog extends StatefulWidget {
  const _PinWizardDialog({required this.steps});

  final List<_PinWizardStep> steps;

  @override
  State<_PinWizardDialog> createState() => _PinWizardDialogState();
}

class _PinWizardDialogState extends State<_PinWizardDialog> {
  static const _pinLength = 6;

  int _stepIndex = 0;
  String _pin = '';
  final List<String> _collected = [];
  String? _error;
  bool _isVerifying = false;

  void _onDigit(String digit) {
    if (_isVerifying || _pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _onDelete() {
    if (_isVerifying || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _onClear() {
    if (_isVerifying || _pin.isEmpty) return;
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  void _onBack() {
    if (_isVerifying) return;
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _stepIndex--;
      _collected.removeLast();
      _pin = '';
      _error = null;
    });
  }

  Future<void> _onNext() async {
    if (_isVerifying) return;

    final step = widget.steps[_stepIndex];
    final error = step.validate?.call(_pin, _collected);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (step.asyncValidate != null) {
      setState(() => _isVerifying = true);
      final asyncError = await step.asyncValidate!(_pin, _collected);
      if (!mounted) return;
      if (asyncError != null) {
        setState(() {
          _isVerifying = false;
          _error = asyncError;
        });
        return;
      }
      setState(() => _isVerifying = false);
    }

    if (_stepIndex == widget.steps.length - 1) {
      Navigator.of(context).pop([..._collected, _pin]);
      return;
    }

    setState(() {
      _collected.add(_pin);
      _stepIndex++;
      _pin = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_stepIndex];
    final isLastStep = _stepIndex == widget.steps.length - 1;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.steps.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Step ${_stepIndex + 1} of ${widget.steps.length}',
                    style: AppTypography.labelSm(color: AppColors.textMuted),
                  ),
                ),
              Text(
                step.title,
                style: AppTypography.headlineSm(color: AppColors.textPrimary),
              ),
              if (step.subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  step.subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinDigitBoxes(pin: _pin, length: _pinLength),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Text(
                    _isVerifying
                        ? 'Checking PIN...'
                        : (_error ?? ' '),
                    style: AppTypography.bodyMd(
                      color: _isVerifying
                          ? AppColors.textMuted
                          : AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Opacity(
                opacity: _isVerifying ? 0.4 : 1,
                child: IgnorePointer(
                  ignoring: _isVerifying,
                  child: PinNumericKeypad(
                    onDigit: _onDigit,
                    onClear: _onClear,
                    onDelete: _onDelete,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: _isVerifying ? null : _onBack,
                    child: Text(_stepIndex == 0 ? 'Cancel' : 'Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _pin.length == _pinLength && !_isVerifying
                        ? _onNext
                        : null,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.onPrimary,
                              ),
                            ),
                          )
                        : Text(isLastStep ? 'Verify' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
