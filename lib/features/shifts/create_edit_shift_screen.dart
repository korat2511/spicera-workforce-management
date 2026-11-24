import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared_widgets/app_section_card.dart';
import '../../shared_widgets/app_segmented_control.dart';
import '../staff/data/shift_api_service.dart';
import '../staff/data/shift_model.dart';

class CreateEditShiftScreen extends StatefulWidget {
  const CreateEditShiftScreen({super.key, this.shift});

  final Shift? shift;

  bool get isEditing => shift != null;

  @override
  State<CreateEditShiftScreen> createState() => _CreateEditShiftScreenState();
}

class _CreateEditShiftScreenState extends State<CreateEditShiftScreen> {
  static const _statusOptions = ['Active', 'Inactive'];

  final _formKey = GlobalKey<FormState>();
  final _shiftApiService = const ShiftApiService();

  late final _nameController = TextEditingController(
    text: widget.shift?.name ?? '',
  );
  late final _shiftTypeController = TextEditingController(
    text: widget.shift?.shiftType ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.shift?.description ?? '',
  );
  late final _breakController = TextEditingController(
    text: '${widget.shift?.breakDurationMinutes ?? 15}',
  );
  late final _graceController = TextEditingController(
    text: '${widget.shift?.gracePeriodMinutes ?? 10}',
  );

  late TimeOfDay _startTime =
      _parseTime(widget.shift?.startTime) ??
      const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime =
      _parseTime(widget.shift?.endTime) ?? const TimeOfDay(hour: 17, minute: 0);
  late final Set<int> _scheduledDays = widget.shift == null
      ? {1, 2, 3, 4, 5, 6, 7}
      : widget.shift!.scheduledDays
            .map((label) => Shift.weekdays.indexOf(label) + 1)
            .toSet();
  late String _status = widget.shift?.isActive == false ? 'Inactive' : 'Active';

  bool _isSaving = false;

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shiftTypeController.dispose();
    _descriptionController.dispose();
    _breakController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _validateMinutes(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Enter a valid number of minutes';
    return null;
  }

  Future<void> _handleSave() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_scheduledDays.isEmpty) {
      SnackbarUtils.showError(context, 'Select at least one scheduled day');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        await _shiftApiService.updateShift(
          shiftId: widget.shift!.id,
          name: _nameController.text.trim(),
          shiftType: _shiftTypeController.text.trim(),
          description: _descriptionController.text.trim(),
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          status: _status.toLowerCase(),
          breakDurationMinutes: int.parse(_breakController.text.trim()),
          gracePeriodMinutes: int.parse(_graceController.text.trim()),
          scheduledDays: _scheduledDays.toList()..sort(),
        );
      } else {
        await _shiftApiService.createShift(
          name: _nameController.text.trim(),
          shiftType: _shiftTypeController.text.trim(),
          description: _descriptionController.text.trim(),
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          status: _status.toLowerCase(),
          breakDurationMinutes: int.parse(_breakController.text.trim()),
          gracePeriodMinutes: int.parse(_graceController.text.trim()),
          scheduledDays: _scheduledDays.toList()..sort(),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showSuccess(
        context,
        widget.isEditing ? 'Shift updated' : 'Shift created',
      );
      NavigationUtils.pop(true, context);
    } on ApiValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showError(context, e.firstMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showError(
        context,
        'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Shift' : 'Add Shift'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              ResponsiveUtils.screenPadding(context) +
              const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            AppSectionCard(
              letter: 'A',
              title: 'Shift Details',
              subtitle: 'Name & description',
              children: [
                _labeledField(
                  label: 'Shift Name',
                  required: true,
                  field: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autocorrect: false,
                    validator: _validateRequired,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _labeledField(
                  label: 'Shift Type',
                  helper: 'e.g. REGULAR, PEAK DINNER, SNACKS & PREP',
                  field: TextFormField(
                    controller: _shiftTypeController,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _labeledField(
                  label: 'Description',
                  field: TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    autocorrect: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'B',
              title: 'Timing',
              subtitle: 'Shift hours & buffers',
              children: [
                _fieldRow(context, [
                  _labeledField(
                    label: 'Start Time',
                    required: true,
                    field: _timeField(_startTime, _pickStartTime),
                  ),
                  _labeledField(
                    label: 'End Time',
                    required: true,
                    field: _timeField(_endTime, _pickEndTime),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Break Duration (mins)',
                    required: true,
                    field: TextFormField(
                      controller: _breakController,
                      keyboardType: TextInputType.number,
                      validator: _validateMinutes,
                    ),
                  ),
                  _labeledField(
                    label: 'Grace Period (mins)',
                    required: true,
                    helper: 'Late tolerance before marked late',
                    field: TextFormField(
                      controller: _graceController,
                      keyboardType: TextInputType.number,
                      validator: _validateMinutes,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'C',
              title: 'Scheduling',
              subtitle: 'Active days & status',
              children: [
                Text(
                  'Scheduled Days',
                  style: AppTypography.labelLg(
                    color: AppColors.textPrimary,
                  ).copyWith(fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < Shift.weekdays.length; i++)
                      _dayToggle(i + 1, Shift.weekdays[i]),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _labeledField(
                  label: 'Status',
                  required: true,
                  field: AppSegmentedControl(
                    options: _statusOptions,
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _dayToggle(int dayNumber, String label) {
    final selected = _scheduledDays.contains(dayNumber);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _scheduledDays.remove(dayNumber);
        } else {
          _scheduledDays.add(dayNumber);
        }
      }),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMd(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _timeField(TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.schedule, size: 18),
        ),
        child: Text(
          _formatTimeOfDay(time),
          style: AppTypography.bodyLg(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding:
          ResponsiveUtils.screenPadding(context) +
          const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Fields marked * are required.',
                style: AppTypography.bodyMd(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      NavigationUtils.pop(false, context);
                    },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                      ),
                    )
                  : Text(widget.isEditing ? 'Save Changes' : 'Create Shift'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    bool required = false,
    String? helper,
    required Widget field,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.labelLg(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 15),
            children: [
              TextSpan(text: label),
              if (required)
                TextSpan(
                  text: ' *',
                  style: AppTypography.labelLg(
                    color: AppColors.error,
                  ).copyWith(fontSize: 15),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        field,
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(helper, style: AppTypography.bodyMd(color: AppColors.textMuted)),
        ],
      ],
    );
  }

  Widget _fieldRow(BuildContext context, List<Widget> children) {
    if (ResponsiveUtils.isMobile(context)) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}
