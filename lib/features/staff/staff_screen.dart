import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import 'create_staff_screen.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(AppRadius.panel),
              ),
              child: const Icon(
                Icons.people_outline,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No staff added yet',
              style: AppTypography.headlineMd(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first team member to start tracking\nattendance and payroll.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => NavigationUtils.push(
                const CreateStaffScreen(),
                context: context,
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }
}
