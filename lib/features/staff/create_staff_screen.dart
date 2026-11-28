import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared_widgets/app_section_card.dart';
import '../../shared_widgets/app_segmented_control.dart';
import 'data/staff_api_service.dart';
import 'staff_pin_shift_screen.dart';

class CreateStaffScreen extends StatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  static const _employmentTypes = ['Full-time', 'Part-time', 'Casual', 'Other'];
  static const _salaryTypes = ['Monthly', 'Weekly', 'Daily', 'Hourly'];
  static const _overtimeRateTypeKeys = ['not_eligible', '1x', '1.5x', '2x', 'custom'];
  static const _overtimeRateTypeLabels = ['Not Eligible', '1x', '1.5x', '2x', 'Custom'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _states = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'];

  final _formKey = GlobalKey<FormState>();
  final _staffApiService = const StaffApiService();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _salaryRateController = TextEditingController();
  final _overtimeCustomRateController = TextEditingController();
  final _dailyHourLimitController = TextEditingController();
  final _weeklyHourLimitController = TextEditingController();
  final _monthlyHourLimitController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _suburbController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime _joiningDate = DateTime.now();
  DateTime _effectiveFromDate = DateTime.now();
  bool _effectiveFromDateEditedManually = false;
  String? _gender;
  String? _state;
  String _employmentType = _employmentTypes.first;
  String _salaryType = _salaryTypes.first;
  String _overtimeRateType = 'not_eligible';
  String _overtimeCustomType = 'multiplier';
  bool _isSaving = false;
  File? _profilePhoto;

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
    _streetAddressController.dispose();
    _suburbController.dispose();
    _postcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
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
      setState(() {
        _joiningDate = picked;
        if (!_effectiveFromDateEditedManually) {
          _effectiveFromDate = picked;
        }
      });
    }
  }

  Future<void> _pickEffectiveFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFromDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _effectiveFromDate = picked;
        _effectiveFromDateEditedManually = true;
      });
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final (firstName, lastName) = _splitFullName();
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

    try {
      final created = await _staffApiService.createStaff(
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
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        streetAddress: _streetAddressController.text.trim(),
        suburb: _suburbController.text.trim(),
        state: _state,
        postcode: _postcodeController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        notes: _notesController.text.trim(),
        profilePhoto: _profilePhoto,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showSuccess(
        context,
        '${created.fullName} added (${created.staffCode})',
      );
      NavigationUtils.push(
        StaffPinShiftScreen(staff: created),
        context: context,
      );
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
      appBar: AppBar(title: const Text('Add Staff')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              ResponsiveUtils.screenPadding(context) +
              const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            AppSectionCard(
              letter: 'A',
              title: 'Personal Details',
              subtitle: 'Identity & contact',
              children: [
                _avatarPicker(),
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Date of Birth',
                    field: _dateField(
                      value: _dateOfBirth == null
                          ? null
                          : _formatDate(_dateOfBirth!),
                      hint: 'Select date',
                      onTap: _pickDateOfBirth,
                    ),
                  ),
                  _labeledField(
                    label: 'Gender',
                    field: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      hint: const Text('Select'),
                      items: [
                        for (final g in _genders)
                          DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'B',
              title: 'Employment Details',
              subtitle: 'Role & address',
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Address (optional)',
                  style: AppTypography.bodyMd(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                _labeledField(
                  label: 'Street Address',
                  field: TextFormField(
                    controller: _streetAddressController,
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Suburb',
                    field: TextFormField(
                      controller: _suburbController,
                      autocorrect: false,
                    ),
                  ),
                  _labeledField(
                    label: 'State',
                    field: DropdownButtonFormField<String>(
                      initialValue: _state,
                      hint: const Text('Select'),
                      items: [
                        for (final s in _states)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) => setState(() => _state = v),
                    ),
                  ),
                  _labeledField(
                    label: 'Postcode',
                    field: TextFormField(
                      controller: _postcodeController,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
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
                const SizedBox(height: AppSpacing.lg),
                _labeledField(
                  label: 'Effective From Date',
                  required: true,
                  helper: 'Defaults to the joining date',
                  field: _dateField(
                    value: _formatDate(_effectiveFromDate),
                    onTap: _pickEffectiveFromDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'D',
              title: 'Notes',
              subtitle: 'Optional',
              children: [
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText:
                        'Anything else worth noting about this staff member',
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

  Widget _avatarPicker() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showPhotoSourceSheet,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: _profilePhoto == null
                ? Text(
                    _initials(),
                    style: AppTypography.headlineSm(color: AppColors.onPrimary),
                  )
                : Image.file(
                    _profilePhoto!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _showPhotoSourceSheet,
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: Text(_profilePhoto == null ? 'Upload Photo' : 'Change Photo'),
        ),
        if (_profilePhoto != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () => setState(() => _profilePhoto = null),
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            tooltip: 'Remove photo',
          ),
        ],
      ],
    );
  }

  Future<void> _showPhotoSourceSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.panel),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'Add Staff Photo',
                  style: AppTypography.headlineSm(color: AppColors.textPrimary),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Take Photo',
                  style: AppTypography.bodyLg(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTypography.bodyLg(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final file = await ImageUtils.pickImage(source);
    if (file == null || !mounted) return;

    if (!await ImageUtils.isWithinSizeLimit(file)) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Photo must be under 5MB');
      return;
    }

    setState(() => _profilePhoto = file);
  }

  String _initials() {
    final words = _fullNameController.text.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).take(2);
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  Widget _dateField({
    required String? value,
    String hint = '',
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value ?? hint,
          style: AppTypography.bodyLg(
            color: value == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
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
                  : const Text('Save & Next'),
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
