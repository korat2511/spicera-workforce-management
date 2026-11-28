import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/navigation_utils.dart';
import '../../shared_widgets/pin_keypad.dart';
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
    if (_isSubmitting || _pin.length != _pinLength) return;

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
            PinDigitBoxes(pin: _pin, length: _pinLength),
            SizedBox(
              height: 24,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _isSubmitting ? 'Checking your PIN...' : (_error ?? ' '),
                  style: AppTypography.bodyMd(
                    color: _isSubmitting
                        ? AppColors.textMuted
                        : AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PinNumericKeypad(
              onDigit: _onDigit,
              onClear: _onClear,
              onDelete: _onDelete,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: _isSubmitting
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
                    : const Icon(Icons.verified_user_outlined, size: 20),
                label: Text(
                  _isSubmitting ? 'Verifying...' : 'Verify & Mark Attendance',
                ),
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
