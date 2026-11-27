import 'package:flutter/material.dart';

import '../../core/auth/kiosk_device_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/settings/font_scale_controller.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../shared_widgets/app_section_card.dart';
import 'kiosk_devices_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _presets = [
    (label: 'Small', scale: 0.9),
    (label: 'Default', scale: 1.0),
    (label: 'Large', scale: 1.15),
    (label: 'Extra Large', scale: FontScaleController.max),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          ResponsiveUtils.screenPadding(context) +
          const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          AppSectionCard(
            letter: 'A',
            title: 'Display',
            subtitle: 'Adjust text size for comfortable reading',
            children: [
              ValueListenableBuilder<double>(
                valueListenable: fontScaleController,
                builder: (context, scale, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Font Size',
                            style: AppTypography.titleMd(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(scale * 100).round()}%',
                            style: AppTypography.labelLg(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text(
                            'A',
                            style: AppTypography.bodySm(
                              color: AppColors.textMuted,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: scale,
                              min: FontScaleController.min,
                              max: FontScaleController.max,
                              divisions: 9,
                              label: '${(scale * 100).round()}%',
                              onChanged: (value) =>
                                  fontScaleController.setScale(value),
                            ),
                          ),
                          Text(
                            'A',
                            style: AppTypography.headlineSm(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final preset in _presets)
                            ChoiceChip(
                              label: Text(preset.label),
                              selected: scale == preset.scale,
                              onSelected: (_) =>
                                  fontScaleController.setScale(preset.scale),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(AppRadius.base),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preview',
                              style: AppTypography.labelMd(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Rutvik Jivanbhai Korat',
                              style: AppTypography.headlineSm(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'JDH001 · Head Chef',
                              style: AppTypography.bodyMd(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionCard(
            letter: 'B',
            title: 'Kiosk Devices',
            subtitle: 'Devices that can mark staff attendance',
            children: [_KioskDevicesSummaryRow()],
          ),
        ],
      ),
    );
  }
}

class _KioskDevicesSummaryRow extends StatelessWidget {
  const _KioskDevicesSummaryRow();

  @override
  Widget build(BuildContext context) {
    final isPaired = kioskDeviceController.isPaired;

    return Material(
      color: AppColors.surfaceInput,
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.base),
        onTap: () =>
            NavigationUtils.push(const KioskDevicesScreen(), context: context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                isPaired ? Icons.check_circle_outline : Icons.info_outline,
                color: isPaired ? AppColors.onDutyText : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isPaired
                      ? 'This device is paired as a kiosk'
                      : "This device isn't registered as a kiosk",
                  style: AppTypography.bodyMd(color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
