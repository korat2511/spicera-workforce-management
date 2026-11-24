import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared_widgets/app_segmented_control.dart';
import 'create_staff_screen.dart';
import 'data/staff_api_service.dart';
import 'data/staff_model.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  static const _statusOptions = ['All', 'Active', 'Inactive'];
  static const _employmentTypeOptions = [
    'All',
    'Full-time',
    'Part-time',
    'Casual',
    'Other',
  ];

  final _staffApiService = const StaffApiService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  final _items = <Staff>[];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;

  String _statusFilter = 'All';
  String _employmentTypeFilter = 'All';

  bool get _hasActiveFilters =>
      _statusFilter != 'All' || _employmentTypeFilter != 'All';

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadFirstPage);
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final page = await _staffApiService.getStaffList(
        search: _searchController.text.trim(),
        status: _statusFilter == 'All' ? null : _statusFilter.toLowerCase(),
        employmentType: _employmentTypeFilter == 'All'
            ? null
            : _employmentTypeFilter,
        page: 1,
      );

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _total = page.total;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load staff. Please try again.';
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    try {
      final page = await _staffApiService.getStaffList(
        search: _searchController.text.trim(),
        status: _statusFilter == 'All' ? null : _statusFilter.toLowerCase(),
        employmentType: _employmentTypeFilter == 'All'
            ? null
            : _employmentTypeFilter,
        page: _currentPage + 1,
      );

      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      SnackbarUtils.showError(context, 'Could not load more staff.');
    }
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _FilterDialog(
        initialStatus: _statusFilter,
        initialEmploymentType: _employmentTypeFilter,
      ),
    );

    if (result == null) return;

    setState(() {
      _statusFilter = result.$1;
      _employmentTypeFilter = result.$2;
    });
    _loadFirstPage();
  }

  void _goToAddStaff() {
    NavigationUtils.push(const CreateStaffScreen(), context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding:
          ResponsiveUtils.screenPadding(context) +
          const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'Search by name, staff code or phone',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _openFilterDialog,
                tooltip: 'Filters',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceInput,
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                ),
                icon: const Icon(
                  Icons.filter_list,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_hasActiveFilters)
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
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _goToAddStaff,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loadFirstPage,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        padding:
            ResponsiveUtils.screenPadding(context) +
            const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildFooter();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _StaffCard(staff: _items[index]),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPage < _lastPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: OutlinedButton(
            onPressed: _loadMore,
            child: const Text('Load More'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Text(
          '$_total staff member${_total == 1 ? '' : 's'}',
          style: AppTypography.bodyMd(color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasSearchOrFilters =
        _searchController.text.trim().isNotEmpty || _hasActiveFilters;

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
              child: Icon(
                hasSearchOrFilters ? Icons.search_off : Icons.people_outline,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasSearchOrFilters ? 'No matching staff' : 'No staff added yet',
              style: AppTypography.headlineMd(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasSearchOrFilters
                  ? 'Try a different search term or clear your filters.'
                  : 'Add your first team member to start tracking\nattendance and payroll.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!hasSearchOrFilters)
              ElevatedButton.icon(
                onPressed: _goToAddStaff,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Staff'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final isActive = staff.status == 'active';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      style: AppTypography.headlineSm(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        staff.staffCode,
                        if (staff.jobTitle != null &&
                            staff.jobTitle!.isNotEmpty)
                          staff.jobTitle!
                        else
                          staff.employmentType,
                      ].join(' · '),
                      style: AppTypography.bodyMd(color: AppColors.textMuted),
                    ),
                    if (staff.shift != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            staff.shift!.label,
                            style: AppTypography.bodySm(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!staff.pinSet) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PIN not set',
                            style: AppTypography.bodySm(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _statusChip(isActive),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => SnackbarUtils.showInfo(
                    context,
                    'Attendance tracking coming soon',
                  ),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Mark Attendance'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => SnackbarUtils.showInfo(
                    context,
                    'Attendance tracking coming soon',
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Clock Out'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showStaffDetail(context, staff),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Status'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final initials = _initialsFor(staff.fullName);

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: staff.profilePhotoUrl == null
          ? Text(
              initials,
              style: AppTypography.labelLg(color: AppColors.onPrimary),
            )
          : Image.network(
              staff.profilePhotoUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text(
                initials,
                style: AppTypography.labelLg(color: AppColors.onPrimary),
              ),
            ),
    );
  }

  Widget _statusChip(bool isActive) {
    final background = isActive
        ? AppColors.onDutyBackground
        : AppColors.offDutyBackground;
    final border = isActive ? AppColors.onDutyBorder : AppColors.offDutyBorder;
    final text = isActive ? AppColors.onDutyText : AppColors.offDutyText;
    final dot = isActive ? AppColors.onDutyDot : AppColors.offDutyDot;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: AppTypography.labelSm(color: text),
          ),
        ],
      ),
    );
  }

  String _initialsFor(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final letters = words.where((w) => w.isNotEmpty).map((w) => w[0]).take(2);
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  void _showStaffDetail(BuildContext context, Staff staff) {
    showDialog<void>(
      context: context,
      builder: (context) => _StaffDetailDialog(staff: staff),
    );
  }
}

class _StaffDetailDialog extends StatelessWidget {
  const _StaffDetailDialog({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.fullName,
                style: AppTypography.headlineSm(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                staff.staffCode,
                style: AppTypography.bodyMd(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              _row('Status', staff.status == 'active' ? 'Active' : 'Inactive'),
              _row('Phone', staff.phone),
              if (staff.email != null) _row('Email', staff.email!),
              _row('Employment Type', staff.employmentType),
              if (staff.jobTitle != null) _row('Job Title', staff.jobTitle!),
              _row('Joining Date', staff.joiningDate),
              _row(
                'Salary',
                '\$${staff.salaryRate} ${staff.currency} / ${staff.salaryType.toLowerCase()}',
              ),
              _row(
                'Shift',
                staff.shift == null ? 'Not assigned' : staff.shift!.label,
              ),
              _row('Attendance PIN', staff.pinSet ? 'Set' : 'Not set'),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodyMd(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMd(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.initialStatus,
    required this.initialEmploymentType,
  });

  final String initialStatus;
  final String initialEmploymentType;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String _status = widget.initialStatus;
  late String _employmentType = widget.initialEmploymentType;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Staff',
                style: AppTypography.headlineSm(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Status',
                style: AppTypography.labelLg(
                  color: AppColors.textPrimary,
                ).copyWith(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSegmentedControl(
                options: _StaffScreenState._statusOptions,
                value: _status,
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Employment Type',
                style: AppTypography.labelLg(
                  color: AppColors.textPrimary,
                ).copyWith(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final option in _StaffScreenState._employmentTypeOptions)
                    ChoiceChip(
                      label: Text(option),
                      selected: _employmentType == option,
                      onSelected: (_) =>
                          setState(() => _employmentType = option),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _status = 'All';
                        _employmentType = 'All';
                      });
                    },
                    child: const Text('Clear'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop((_status, _employmentType)),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
