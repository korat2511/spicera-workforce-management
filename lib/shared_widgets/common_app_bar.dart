import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/date_time_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../features/attendance/gate_screen.dart';
import '../features/auth/data/auth_api_service.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({super.key, this.leading, this.actions});

  final Widget? leading;
  final List<Widget>? actions;

  static const double _height = 100;
  static const double _badgeSize = 40;
  static const double _iconButtonSize = 40;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              ResponsiveUtils.screenPadding(context) +
              const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Container(
                width: _badgeSize,
                height: _badgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Text(
                  'S',
                  style: AppTypography.headlineSm(color: AppColors.onPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Spicera Workforce',
                  style: AppTypography.headlineSm(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const _LiveClock(),
              const SizedBox(width: AppSpacing.md),
              const _NotificationButton(),
              const SizedBox(width: AppSpacing.sm),
              const _UserAvatar(),
              if (actions != null) ...[
                const SizedBox(width: AppSpacing.sm),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CommonAppBar._iconButtonSize,
      height: CommonAppBar._iconButtonSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await const AuthApiService().logout();
    } catch (_) {
      // Best-effort: proceed with clearing the local session regardless.
    }
    await authController.logout();
    if (!context.mounted) return;
    NavigationUtils.pushAndRemoveUntil(const GateScreen(), context: context);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
      ),
      onSelected: (_) => _confirmLogout(context),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.sm),
              Text('Log Out'),
            ],
          ),
        ),
      ],
      child: Container(
        width: CommonAppBar._iconButtonSize,
        height: CommonAppBar._iconButtonSize,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: AppColors.onPrimary, size: 22),
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateTimeUtils.formatDayDate(_now),
          style: AppTypography.bodyMd(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          DateTimeUtils.formatTime(_now),
          style: AppTypography.tabularNums(
            AppTypography.titleMd(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
