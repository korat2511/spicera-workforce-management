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
import 'data/shift_api_service.dart';
import 'data/shift_model.dart';
import 'data/staff_api_service.dart';
import 'data/staff_model.dart';

class StaffPinShiftScreen extends StatefulWidget {
  const StaffPinShiftScreen({super.key, required this.staff});

  final Staff staff;

  @override
  State<StaffPinShiftScreen> createState() => _StaffPinShiftScreenState();
}

class _StaffPinShiftScreenState extends State<StaffPinShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shiftApiService = const ShiftApiService();
  final _staffApiService = const StaffApiService();

  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isSaving = false;

  List<Shift>? _shifts;
  String? _shiftLoadError;
  int? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() => setState(() {}));
    _confirmPinController.addListener(() => setState(() {}));
    _loadShifts();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    setState(() => _shiftLoadError = null);
    try {
      final shifts = await _shiftApiService.getShifts();
      if (!mounted) return;
      setState(() => _shifts = shifts);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _shiftLoadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _shiftLoadError = 'Could not load shifts. Please try again.',
      );
    }
  }

  bool get _pinsMatch =>
      _pinController.text.isNotEmpty &&
      _pinController.text == _confirmPinController.text;

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'PIN must be exactly 6 digits';
    }
    return null;
  }

  String? _validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm the PIN';
    }
    if (value != _pinController.text) {
      return 'PINs do not match';
    }
    return null;
  }

  Future<void> _handleSave() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedShiftId == null) {
      SnackbarUtils.showError(context, 'Please select a shift schedule');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _staffApiService.setPin(
        staffId: widget.staff.id,
        pin: _pinController.text,
        pinConfirmation: _confirmPinController.text,
      );
      await _staffApiService.assignShift(
        staffId: widget.staff.id,
        shiftId: _selectedShiftId!,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtils.showSuccess(
        context,
        '${widget.staff.fullName} is fully set up',
      );
      NavigationUtils.popToRoot(context: context);
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
      appBar: AppBar(title: const Text('Attendance & Shift Setup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              ResponsiveUtils.screenPadding(context) +
              const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            AppSectionCard(
              letter: 'A',
              title: 'Tablet Attendance Access',
              subtitle:
                  'Your 6-digit PIN verifies clock-ins and breaks on the shared kiosk tablet.',
              children: [
                _pinField(
                  label: 'Attendance PIN (6 digits)',
                  controller: _pinController,
                  obscure: _obscurePin,
                  onToggleObscure: () =>
                      setState(() => _obscurePin = !_obscurePin),
                  validator: _validatePin,
                ),
                const SizedBox(height: AppSpacing.lg),
                _pinField(
                  label: 'Confirm PIN',
                  controller: _confirmPinController,
                  obscure: _obscureConfirmPin,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                  validator: _validateConfirmPin,
                  helper: _confirmPinController.text.isNotEmpty
                      ? (_pinsMatch ? 'PINs match' : 'PINs do not match')
                      : null,
                  helperColor: _pinsMatch
                      ? AppColors.onDutyText
                      : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(AppRadius.base),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Stored as a secure one-way hash. The PIN is never '
                          'visible in plain text after this step.',
                          style: AppTypography.bodyMd(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              letter: 'B',
              title: 'Shift Assignment',
              subtitle: 'Assign a schedule for this staff member',
              children: [_shiftPicker()],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _shiftPicker() {
    if (_shiftLoadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shiftLoadError!,
            style: AppTypography.bodyMd(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: _loadShifts, child: const Text('Retry')),
        ],
      );
    }

    if (_shifts == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.labelLg(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 15),
            children: [
              const TextSpan(text: 'Assigned Shift Schedule'),
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
        DropdownButtonFormField<int>(
          initialValue: _selectedShiftId,
          hint: const Text('Select a shift'),
          items: [
            for (final shift in _shifts!)
              DropdownMenuItem(value: shift.id, child: Text(shift.label)),
          ],
          onChanged: (value) => setState(() => _selectedShiftId = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'You can change or reassign shift schedules anytime.',
          style: AppTypography.bodyMd(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _pinField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    String? helper,
    Color? helperColor,
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
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: TextInputType.number,
          autocorrect: false,
          maxLength: 6,
          style: AppTypography.tabularNums(AppTypography.bodyLg()),
          validator: validator,
          decoration: InputDecoration(
            counterText: '',
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(helper, style: AppTypography.bodyMd(color: helperColor)),
        ],
      ],
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
                  : const Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
