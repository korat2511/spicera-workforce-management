import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../shared_widgets/app_bottom_nav_bar.dart';
import '../../shared_widgets/common_app_bar.dart';
import '../more/more_screen.dart';
import '../shifts/shifts_screen.dart';
import '../staff/staff_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  static const _items = [
    AppBottomNavItem(label: 'Dashboard', assetPath: 'assets/svg/dashboard.svg'),
    AppBottomNavItem(label: 'Staff', assetPath: 'assets/svg/staff.svg'),
    AppBottomNavItem(label: 'Shifts', assetPath: 'assets/svg/calender.svg'),
    AppBottomNavItem(
      label: 'Attendance',
      assetPath: 'assets/svg/attendance.svg',
    ),
    AppBottomNavItem(label: 'Payroll', assetPath: 'assets/svg/payroll.svg'),
    AppBottomNavItem(label: 'More', assetPath: 'assets/svg/more.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _items[_selectedIndex];

    return Scaffold(
      appBar: const CommonAppBar(),
      body: switch (selected.label) {
        'Staff' => const StaffScreen(),
        'Shifts' => const ShiftsScreen(),
        'More' => const MoreScreen(),
        _ => Center(
          child: Text(
            '${selected.label} screen',
            style: AppTypography.headlineMd(color: AppColors.textSecondary),
          ),
        ),
      },
      bottomNavigationBar: AppBottomNavBar(
        items: _items,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
