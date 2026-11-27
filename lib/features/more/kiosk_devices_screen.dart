import 'package:flutter/material.dart';

import '../../core/auth/kiosk_device_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import 'data/kiosk_device_api_service.dart';
import 'data/kiosk_device_model.dart';

class KioskDevicesScreen extends StatefulWidget {
  const KioskDevicesScreen({super.key});

  @override
  State<KioskDevicesScreen> createState() => _KioskDevicesScreenState();
}

class _KioskDevicesScreenState extends State<KioskDevicesScreen> {
  final _apiService = const KioskDeviceApiService();

  List<KioskDevice> _devices = [];
  bool _isLoading = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _apiService.list();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarUtils.showError(context, e.message);
    }
  }

  Future<void> _registerThisDevice() async {
    final controller = TextEditingController(text: 'Kiosk Device');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Register This Device',
          style: AppTypography.headlineSm(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This device will be able to mark staff attendance without an '
              'admin logged in.',
              style: AppTypography.bodyMd(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Device Name',
              style: AppTypography.labelLg(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'e.g. Front Counter iPad',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    setState(() => _isRegistering = true);
    try {
      final (device, token) = await _apiService.register(name);
      await kioskDeviceController.pair(deviceId: device.id, token: token);
      if (!mounted) return;
      setState(() => _isRegistering = false);
      SnackbarUtils.showSuccess(context, 'This device is now paired');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isRegistering = false);
      SnackbarUtils.showError(context, e.message);
    }
  }

  Future<void> _unpair(KioskDevice device) async {
    try {
      await _apiService.revoke(device.id);
      if (device.id == kioskDeviceController.pairedDeviceId) {
        await kioskDeviceController.unpair();
      }
      if (!mounted) return;
      setState(() {});
      SnackbarUtils.showSuccess(context, '${device.name} unpaired');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaired = kioskDeviceController.isPaired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk Devices'),
        actions: [
          if (!isPaired)
            IconButton(
              onPressed: _isRegistering ? null : _registerThisDevice,
              icon: _isRegistering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              tooltip: 'Register This Device',
            ),
        ],
      ),
      body: ListView(
        padding:
            ResponsiveUtils.screenPadding(context) +
            const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Text(
            'Devices that can mark staff attendance',
            style: AppTypography.bodyMd(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'All Paired Devices',
            style: AppTypography.labelLg(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_devices.isEmpty)
            Text(
              'No kiosk devices registered yet.',
              style: AppTypography.bodyMd(color: AppColors.textMuted),
            )
          else
            for (final device in _devices) ...[
              _KioskDeviceRow(device: device, onUnpair: () => _unpair(device)),
              if (device != _devices.last)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _KioskDeviceRow extends StatelessWidget {
  const _KioskDeviceRow({required this.device, required this.onUnpair});

  final KioskDevice device;
  final VoidCallback onUnpair;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.base),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                device.platform == 'iOS'
                    ? Icons.phone_iphone
                    : device.platform == 'Android'
                    ? Icons.phone_android
                    : Icons.tablet_mac,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: AppTypography.titleMd(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (device.model != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        device.model!,
                        style: AppTypography.bodySm(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(isRevoked: device.isRevoked),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DeviceDetail(
                    label: 'Paired',
                    value: device.createdAt == null
                        ? '—'
                        : DateTimeUtils.formatApiDateTime(device.createdAt!),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DeviceDetail(
                    label: 'Last Seen',
                    value: device.lastSeenAt == null
                        ? 'Never used'
                        : DateTimeUtils.formatApiDateTime(device.lastSeenAt!),
                  ),
                ),
              ],
            ),
          ),
          if (!device.isRevoked) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onUnpair,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Unpair'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isRevoked});

  final bool isRevoked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isRevoked
            ? AppColors.errorContainer
            : AppColors.onDutyBackground,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isRevoked ? 'Revoked' : 'Active',
        style: AppTypography.labelMd(
          color: isRevoked ? AppColors.onErrorContainer : AppColors.onDutyText,
        ),
      ),
    );
  }
}

class _DeviceDetail extends StatelessWidget {
  const _DeviceDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMd(color: AppColors.textPrimary)),
      ],
    );
  }
}
