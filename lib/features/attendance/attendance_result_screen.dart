import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../../shared_widgets/animated_brand_background.dart';
import '../attendance/gate_screen.dart';
import 'data/attendance_record_model.dart';

class AttendanceResultScreen extends StatefulWidget {
  const AttendanceResultScreen({super.key, required this.record});

  final AttendanceRecord record;

  @override
  State<AttendanceResultScreen> createState() => _AttendanceResultScreenState();
}

class _AttendanceResultScreenState extends State<AttendanceResultScreen> {
  late final Timer _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        NavigationUtils.pushAndRemoveUntil(
          const GateScreen(),
          context: context,
        );
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final actionLabel = record.isCheckIn ? 'Checked In' : 'Checked Out';
    final time = DateTimeUtils.formatTime(record.recordedAt.toLocal());

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBrandBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.level3,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.onDutyText,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    record.staffFullName,
                    style: AppTypography.headlineMd(color: AppColors.onPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$actionLabel at $time',
                    style: AppTypography.titleMd(
                      color: AppColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  if (record.status != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _StatusPill(status: record.status!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Returning to the home screen…',
                    style: AppTypography.bodyMd(
                      color: AppColors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'late' => 'Late',
      'early_leave' => 'Left Early',
      'overtime' => 'Overtime',
      _ => 'On Time',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelLg(color: AppColors.onPrimary),
      ),
    );
  }
}
