import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';

class CreateStaffScreen extends StatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  static const _employmentTypes = ['Full-time', 'Part-time', 'Casual', 'Other'];
  static const _salaryTypes = ['Monthly', 'Daily', 'Hourly'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _states = ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT'];

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _salaryRateController = TextEditingController();
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
  bool _isSaving = false;
  File? _profilePhoto;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    _salaryRateController.dispose();
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

  void _handleSave() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    // No backend wiring yet — the create-staff API call lands when the
    // app's networking layer is built. This confirms the form is valid
    // and gives save/loading feedback in the meantime.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showSuccess(context, 'Staff profile ready to save');
      NavigationUtils.pop(null, context);
    });
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
            _SectionCard(
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
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Full name is required'
                        : null,
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
            _SectionCard(
              letter: 'B',
              title: 'Employment Details',
              subtitle: 'Role & address',
              children: [
                _labeledField(
                  label: 'Employment Type',
                  required: true,
                  field: _SegmentedControl(
                    options: _employmentTypes,
                    value: _employmentType,
                    onChanged: (v) => setState(() => _employmentType = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Job Title',
                    field: TextFormField(controller: _jobTitleController),
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
                  field: TextFormField(controller: _streetAddressController),
                ),
                const SizedBox(height: AppSpacing.lg),
                _fieldRow(context, [
                  _labeledField(
                    label: 'Suburb',
                    field: TextFormField(controller: _suburbController),
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
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionCard(
              letter: 'C',
              title: 'Compensation Details',
              subtitle: 'Payroll & wages',
              children: [
                _labeledField(
                  label: 'Salary Calculation Method',
                  required: true,
                  field: _SegmentedControl(
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
                    validator: _validateSalaryRate,
                    decoration: const InputDecoration(prefixText: '\$ '),
                  ),
                ),
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
            _SectionCard(
              letter: 'D',
              title: 'Notes',
              subtitle: 'Optional',
              children: [
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.letter,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String letter;
  final String title;
  final String subtitle;
  final List<Widget> children;

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
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Text(
                  letter,
                  style: AppTypography.labelMd(color: AppColors.onPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSm(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMd(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(child: _segment(options[i])),
          if (i != options.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _segment(String option) {
    final selected = option == value;
    return GestureDetector(
      onTap: () => onChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          option,
          textAlign: TextAlign.center,
          style: AppTypography.labelLg(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
