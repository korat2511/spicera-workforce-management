import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';

class AppBottomNavItem {
  const AppBottomNavItem({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavBarButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSlotHeight = 28;
  static const double _selectedRadius = 14;
  static const Duration _duration = Duration(milliseconds: 280);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final targetColor = selected
        ? AppColors.navItemSelected
        : AppColors.navItemUnselected;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_selectedRadius),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navItemSelectedBackground
              : Colors.transparent,
          borderRadius: BorderRadius.circular(_selectedRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: _duration,
              curve: Curves.easeOutBack,
              child: SizedBox(
                height: _iconSlotHeight,
                child: Center(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: targetColor),
                    duration: _duration,
                    curve: _curve,
                    builder: (context, color, child) {
                      return SvgPicture.asset(
                        item.assetPath,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          color ?? targetColor,
                          BlendMode.srcIn,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: _duration,
              curve: _curve,
              style: _navLabelStyle(targetColor),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  /// Pinned at 11px — this is the one place in the app that keeps the
  /// original compact label size rather than the larger shared
  /// AppTypography.labelSm, per an explicit approved design spec for the
  /// bottom nav bar.
  TextStyle _navLabelStyle(Color color) {
    return GoogleFonts.beVietnamPro(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 14 / 11,
      letterSpacing: 0.33,
      color: color,
    );
  }
}
