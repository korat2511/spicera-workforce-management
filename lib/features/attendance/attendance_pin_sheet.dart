import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/navigation_utils.dart';
import 'attendance_result_screen.dart';
import 'data/attendance_api_service.dart';

/// Shows the PIN-entry bottom sheet over the camera screen. On success,
/// navigates (via the global navigator, not the sheet's own context — the
/// sheet is already closing by that point) to the result screen.
Future<void> showAttendancePinSheet(
  BuildContext context, {
  required File photo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AttendancePinSheet(photo: photo),
  );
}

class _AttendancePinSheet extends StatefulWidget {
  const _AttendancePinSheet({required this.photo});

  final File photo;

  @override
  State<_AttendancePinSheet> createState() => _AttendancePinSheetState();
}

class _AttendancePinSheetState extends State<_AttendancePinSheet> {
  static const _pinLength = 6;

  final _apiService = const AttendanceApiService();
  String _pin = '';
  bool _isSubmitting = false;
  String? _error;

  void _onDigit(String digit) {
    if (_isSubmitting || _pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _onDelete() {
    if (_isSubmitting || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _onClear() {
    if (_isSubmitting || _pin.isEmpty) return;
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_pin.length != _pinLength) return;

    setState(() => _isSubmitting = true);

    try {
      final record = await _apiService.punch(pin: _pin, photo: widget.photo);
      if (!mounted) return;
      Navigator.of(context).pop();
      NavigationUtils.pushAndRemoveUntil(
        AttendanceResultScreen(record: record),
      );
    } on ApiValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _pin = '';
        _error = e.firstMessage;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _pin = '';
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _pin = '';
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _pin.length == _pinLength && !_isSubmitting;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.panel),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(AppRadius.base),
              ),
              child: const Icon(
                Icons.pin_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Enter Your Personal PIN',
              style: AppTypography.headlineSm(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your confidential 6-digit staff PIN to record your '
              'attendance.',
              style: AppTypography.bodyMd(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PinBoxes(pin: _pin, length: _pinLength),
            SizedBox(
              height: 24,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      )
                    : Text(
                        _error ?? ' ',
                        style: AppTypography.bodyMd(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Keypad(onDigit: _onDigit, onClear: _onClear, onDelete: _onDelete),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: const Icon(Icons.verified_user_outlined, size: 20),
                label: const Text('Verify & Mark Attendance'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel & Exit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBoxes extends StatelessWidget {
  const _PinBoxes({required this.pin, required this.length});

  final String pin;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          _PinBox(isFilled: i < pin.length),
          if (i != length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({required this.isFilled});

  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFilled ? AppColors.surfaceHighlight : AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(
          color: isFilled ? AppColors.primary : AppColors.border,
          width: isFilled ? 2 : 1,
        ),
      ),
      child: isFilled
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onClear,
    required this.onDelete,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  static const _letters = {
    '1': '',
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '',
  };

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final digit in row) ...[
                  _KeypadButton(
                    label: digit,
                    letters: _letters[digit]!,
                    onTap: () => onDigit(digit),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KeypadButton(
              label: 'Clear',
              letters: 'Reset All',
              isSmallLabel: true,
              onTap: onClear,
            ),
            const SizedBox(width: AppSpacing.md),
            _KeypadButton(label: '0', letters: '', onTap: () => onDigit('0')),
            const SizedBox(width: AppSpacing.md),
            _KeypadButton(
              icon: Icons.backspace_outlined,
              letters: 'Delete',
              onTap: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.letters,
    this.isSmallLabel = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final String letters;
  final bool isSmallLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceInput,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, color: AppColors.textPrimary, size: 24)
                else if (isSmallLabel)
                  Text(
                    label!,
                    style: AppTypography.labelLg(color: AppColors.textPrimary),
                  )
                else
                  Text(
                    label!,
                    style: AppTypography.headlineSm(
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    style: AppTypography.labelSm(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
