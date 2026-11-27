import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import '../staff/data/shift_model.dart';
import '../staff/data/staff_api_service.dart';
import '../staff/data/staff_model.dart';

class AssignStaffToShiftDialog extends StatefulWidget {
  const AssignStaffToShiftDialog({super.key, required this.shift});

  final Shift shift;

  @override
  State<AssignStaffToShiftDialog> createState() =>
      _AssignStaffToShiftDialogState();
}

class _AssignStaffToShiftDialogState extends State<AssignStaffToShiftDialog> {
  final _staffApiService = const StaffApiService();

  List<Staff> _staff = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final page = await _staffApiService.getStaffList(perPage: 100);
      if (!mounted) return;
      setState(() {
        _staff = page.items
            .where((staff) => staff.shift?.id != widget.shift.id)
            .toList();
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
        _loadError = 'Could not load staff. Please try again.';
      });
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedIds.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await Future.wait(
        _selectedIds.map(
          (id) => _staffApiService.assignShift(
            staffId: id,
            shiftId: widget.shift.id,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showError(
        context,
        'Could not assign staff. Please try again.',
      );
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
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Staff',
                style: AppTypography.headlineSm(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.shift.name,
                style: AppTypography.bodyMd(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Flexible(child: _buildBody()),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleAssign,
                    child: _isSaving
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
                        : Text('Assign (${_selectedIds.length})'),
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

    if (_staff.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No other staff available to assign.',
          style: AppTypography.bodyMd(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _staff.length,
      itemBuilder: (context, index) {
        final staff = _staff[index];
        final selected = _selectedIds.contains(staff.id);

        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: selected,
          onChanged: (_) => setState(() {
            if (selected) {
              _selectedIds.remove(staff.id);
            } else {
              _selectedIds.add(staff.id);
            }
          }),
          title: Text(
            staff.fullName,
            style: AppTypography.bodyLg(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            staff.shift == null
                ? staff.staffCode
                : '${staff.staffCode} · Currently in ${staff.shift!.name}',
            style: AppTypography.bodySm(color: AppColors.textMuted),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }
}

class ManageShiftStaffDialog extends StatefulWidget {
  const ManageShiftStaffDialog({super.key, required this.shift});

  final Shift shift;

  @override
  State<ManageShiftStaffDialog> createState() => _ManageShiftStaffDialogState();
}

class _ManageShiftStaffDialogState extends State<ManageShiftStaffDialog> {
  final _staffApiService = const StaffApiService();

  List<Staff> _staff = [];
  bool _isLoading = true;
  String? _loadError;
  bool _changed = false;
  final Set<int> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final page = await _staffApiService.getStaffList(perPage: 100);
      if (!mounted) return;
      setState(() {
        _staff = page.items
            .where((staff) => staff.shift?.id == widget.shift.id)
            .toList();
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
        _loadError = 'Could not load staff. Please try again.';
      });
    }
  }

  Future<void> _unassign(Staff staff) async {
    setState(() => _removingIds.add(staff.id));

    try {
      await _staffApiService.assignShift(staffId: staff.id, shiftId: null);
      if (!mounted) return;
      setState(() {
        _staff.removeWhere((s) => s.id == staff.id);
        _removingIds.remove(staff.id);
        _changed = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _removingIds.remove(staff.id));
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _removingIds.remove(staff.id));
      SnackbarUtils.showError(
        context,
        'Could not remove staff. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Dialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.panel),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Staff',
                  style: AppTypography.headlineSm(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.shift.name,
                  style: AppTypography.bodyMd(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(child: _buildBody()),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_changed),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
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

    if (_staff.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No staff assigned to this shift yet.',
          style: AppTypography.bodyMd(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _staff.length,
      itemBuilder: (context, index) {
        final staff = _staff[index];
        final removing = _removingIds.contains(staff.id);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            staff.fullName,
            style: AppTypography.bodyLg(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            staff.staffCode,
            style: AppTypography.bodySm(color: AppColors.textMuted),
          ),
          trailing: removing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: () => _unassign(staff),
                  icon: const Icon(Icons.close, color: AppColors.error),
                  tooltip: 'Remove from shift',
                ),
        );
      },
    );
  }
}
