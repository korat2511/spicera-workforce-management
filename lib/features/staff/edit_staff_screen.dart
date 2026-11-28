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
import 'data/staff_api_service.dart';
import 'data/staff_model.dart';

class EditStaffScreen extends StatefulWidget {
  const EditStaffScreen({super.key, required this.staff});

  final Staff staff;

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  static const _employmentTypes = ['Full-time', 'Part-time', 'Casual', 'Other'];
  static const _salaryTypes = ['Monthly', 'Weekly', 'Daily', 'Hourly'];
  static const _overtimeRateTypeKeys = ['not_eligible', '1x', '1.5x', '2x', 'custom'];
  static const _overtimeRateTypeLabels = ['Not Eligible', '1x', '1.5x', '2x', 'Custom'];

  final _formKey = GlobalKey<FormState>();
  final _staffApiService = const StaffApiService();

  late final _fullNameController = TextEditingController(
    text: widget.staff.fullName,
  );
  late final _phoneController = TextEditingController(
    text: widget.staff.phone.replaceFirst(RegExp(r'^0'), ''),
  );
  late final _emailController = TextEditingController(
    text: widget.staff.email ?? '',
  );
  late final _jobTitleController = TextEditingController(
    text: widget.staff.jobTitle ?? '',
  );
  late final _salaryRateController = TextEditingController(
    text: widget.staff.salaryRate,
  );
  late final _overtimeCustomRateController = TextEditingController(
    text: widget.staff.overtimeCustomRate ?? '',
  );
  late final _dailyHourLimitController = TextEditingController(
    text: widget.staff.dailyHourLimit ?? '',
  );
  late final _weeklyHourLimitController = TextEditingController(
    text: widget.staff.weeklyHourLimit ?? '',
  );
  late final _monthlyHourLimitController = TextEditingController(
    text: widget.staff.monthlyHourLimit ?? '',
  );

  late DateTime _joiningDate = DateTime.parse(widget.staff.joiningDate);
  late String _employmentType =
      _employmentTypes.contains(widget.staff.employmentType)
      ? widget.staff.employmentType
      : _employmentTypes.first;
  late String _salaryType = _salaryTypes.contains(widget.staff.salaryType)
      ? widget.staff.salaryType
      : _salaryTypes.first;
  late String _overtimeRateType =
      _overtimeRateTypeKeys.contains(widget.staff.overtimeRateType)
      ? widget.staff.overtimeRateType
      : 'not_eligible';
  late String _overtimeCustomType =
      widget.staff.overtimeCustomType == 'fixed_rate'
      ? 'fixed_rate'
      : 'multiplier';

  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    _salaryRateController.dispose();
    _overtimeCustomRateController.dispose();
    _dailyHourLimitController.dispose();
    _weeklyHourLimitController.dispose();
    _monthlyHourLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _validateFullName(String? value) {
    final parts = (value ?? '').trim().split(RegExp(r'\s+'));
    if (parts.where((p) => p.isNotEmpty).length < 2) {
      return 'Enter both first and last name';
    }
    return null;
  }

  (String, String) _splitFullName() {
    final parts = _fullNameController.text.trim().split(RegExp(r'\s+'));
    return (parts.first, parts.skip(1).join(' '));
  }

  String? _validateAustralianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 9 || !RegExp(r'^[2-478]').hasMatch(digits)) {
      return 'Enter a valid Australian phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return valid ? null : 'Enter a valid email address';
  }

  String? _validateSalaryRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Salary rate is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid non-negative amount';
    }
    return null;
  }

  String? _validateOvertimeCustomRate(String? value) {
    if (_overtimeRateType != 'custom') {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return _overtimeCustomType == 'fixed_rate'
          ? 'Custom hourly rate is required'
          : 'Custom multiplier is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid non-negative amount';
    }
    return null;
  }

  String? _validateDailyHourLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 24) {
      return 'Enter hours between 0 and 24';
    }
    return null;
  }

  String? _validateWeeklyHourLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 168) {
      return 'Enter hours between 0 and 168';
    }
    return null;
  }

  String? _validateMonthlyHourLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 744) {
      return 'Enter hours between 0 and 744';
    }
    return null;
  }

  Future<void> _handleSave() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final (firstName, lastName) = _splitFullName();
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

    try {
      final updated = await _staffApiService.updateStaff(
        staffId: widget.staff.id,
        firstName: firstName,
        lastName: lastName,
        phone: '+61$phoneDigits',
        employmentType: _employmentType,
        joiningDate: _joiningDate,
        salaryType: _salaryType,
        salaryRate: double.parse(_salaryRateController.text.trim()),
        overtimeRateType: _overtimeRateType,
        overtimeCustomType: _overtimeRateType == 'custom'
            ? _overtimeCustomType
            : null,
        overtimeCustomRate: _overtimeRateType == 'custom'
            ? double.parse(_overtimeCustomRateController.text.trim())
            : null,
        dailyHourLimit: _dailyHourLimitController.text.trim().isEmpty
            ? null
            : double.parse(_dailyHourLimitController.text.trim()),
        weeklyHourLimit:
            _salaryType == 'Weekly' &&
                _weeklyHourLimitController.text.trim().isNotEmpty
            ? double.parse(_weeklyHourLimitController.text.trim())
            : null,
        monthlyHourLimit:
            _salaryType == 'Monthly' &&
                _monthlyHourLimitController.text.trim().isNotEmpty
            ? double.parse(_monthlyHourLimitController.text.trim())
            : null,
        email: _emailController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showSuccess(context, 'Staff details updated');
      NavigationUtils.pop(updated, context);
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
      appBar: AppBar(title: const Text('Edit Staff')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              ResponsiveUtils.screenPadding(context) +
              const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            _EditStaffHeader(staff: widget.staff),
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              letter: 'A',
              title: 'Personal Details',
              subtitle: 'Identity & contact',
              children: [
                _labeledField(
                  label: 'Full Name',
                  required: true,
                  field: TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    autocorrect: false,
                    validator: _validateFullName,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Phone',
                    required: true,
                    field: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      validator: _validateAustralianPhone,
                      decoration: const InputDecoration(
                        prefixText: '+61 ',
                        hintText: '412 345 678',
                      ),
                    ),
                  ),
                  _labeledField(
                    label: 'Email',
                    field: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: _validateEmail,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'B',
              title: 'Employment Details',
              subtitle: 'Role & dates',
              children: [
                _labeledField(
                  label: 'Employment Type',
                  required: true,
                  field: AppSegmentedControl(
                    options: _employmentTypes,
                    value: _employmentType,
                    onChanged: (v) => setState(() => _employmentType = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Job Title',
                    field: TextFormField(
                      controller: _jobTitleController,
                      autocorrect: false,
                    ),
                  ),
                  _labeledField(
                    label: 'Joining Date',
                    required: true,
                    field: _dateField(
                      value: _formatDate(_joiningDate),
                      onTap: _pickJoiningDate,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'C',
              title: 'Compensation Details',
              subtitle: 'Payroll & wages',
              children: [
                _labeledField(
                  label: 'Salary Calculation Method',
                  required: true,
                  field: AppSegmentedControl(
                    options: _salaryTypes,
                    value: _salaryType,
                    onChanged: (v) => setState(() => _salaryType = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _labeledField(
                  label: 'Salary Rate',
                  required: true,
                  helper: 'AUD, per ${_salaryType.toLowerCase()} rate',
                  field: TextFormField(
                    controller: _salaryRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autocorrect: false,
                    validator: _validateSalaryRate,
                    decoration: const InputDecoration(prefixText: '\$ '),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _labeledField(
                  label: 'Overtime Pay Rate',
                  required: true,
                  helper: 'How overtime hours are paid relative to the regular rate',
                  field: AppSegmentedControl(
                    options: _overtimeRateTypeLabels,
                    value: _overtimeRateTypeLabels[_overtimeRateTypeKeys.indexOf(
                      _overtimeRateType,
                    )],
                    onChanged: (v) => setState(() {
                      _overtimeRateType =
                          _overtimeRateTypeKeys[_overtimeRateTypeLabels.indexOf(
                            v,
                          )];
                    }),
                  ),
                ),
                if (_overtimeRateType == 'custom') ...[
                  const SizedBox(height: AppSpacing.lg),
                  _labeledField(
                    label: 'Custom Overtime Type',
                    required: true,
                    field: AppSegmentedControl(
                      options: const ['Multiplier', 'Fixed Rate'],
                      value: _overtimeCustomType == 'fixed_rate'
                          ? 'Fixed Rate'
                          : 'Multiplier',
                      onChanged: (v) => setState(() {
                        _overtimeCustomType = v == 'Fixed Rate'
                            ? 'fixed_rate'
                            : 'multiplier';
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _labeledField(
                    label: _overtimeCustomType == 'fixed_rate'
                        ? 'Custom Hourly Rate'
                        : 'Custom Multiplier',
                    required: true,
                    helper: _overtimeCustomType == 'fixed_rate'
                        ? 'AUD paid per overtime hour'
                        : 'e.g. 1.75 pays 1.75x the regular rate',
                    field: TextFormField(
                      controller: _overtimeCustomRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autocorrect: false,
                      validator: _validateOvertimeCustomRate,
                      decoration: InputDecoration(
                        prefixText: _overtimeCustomType == 'fixed_rate'
                            ? '\$ '
                            : null,
                        suffixText: _overtimeCustomType == 'multiplier'
                            ? 'x'
                            : null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Daily Hour Limit',
                    helper: 'Hours/day before overtime applies',
                    field: TextFormField(
                      controller: _dailyHourLimitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autocorrect: false,
                      validator: _validateDailyHourLimit,
                      decoration: const InputDecoration(suffixText: 'hrs'),
                    ),
                  ),
                  if (_salaryType == 'Weekly')
                    _labeledField(
                      label: 'Weekly Hour Limit',
                      helper: 'Hours/week before overtime applies',
                      field: TextFormField(
                        controller: _weeklyHourLimitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autocorrect: false,
                        validator: _validateWeeklyHourLimit,
                        decoration: const InputDecoration(suffixText: 'hrs'),
                      ),
                    )
                  else if (_salaryType == 'Monthly')
                    _labeledField(
                      label: 'Monthly Hour Limit',
                      helper: 'Hours/month before overtime applies',
                      field: TextFormField(
                        controller: _monthlyHourLimitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autocorrect: false,
                        validator: _validateMonthlyHourLimit,
                        decoration: const InputDecoration(suffixText: 'hrs'),
                      ),
                    ),
                ]),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _dateField({required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value,
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
                      NavigationUtils.pop(null, context);
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
                  : const Text('Save Changes'),
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

class _EditStaffHeader extends StatelessWidget {
  const _EditStaffHeader({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(staff.fullName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: staff.profilePhotoUrl == null
                ? Text(
                    initials,
                    style: AppTypography.headlineSm(color: AppColors.primary),
                  )
                : Image.network(
                    staff.profilePhotoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Text(
                      initials,
                      style: AppTypography.headlineSm(color: AppColors.primary),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        staff.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
                        style: AppTypography.labelSm(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  staff.jobTitle != null && staff.jobTitle!.isNotEmpty
                      ? staff.jobTitle!
                      : staff.employmentType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd(color: AppColors.primary),
                ),
              ],
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
