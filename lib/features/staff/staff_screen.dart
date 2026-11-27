import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import 'create_staff_screen.dart';
import 'data/staff_api_service.dart';
import 'data/staff_model.dart';
import 'staff_profile_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
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

  int _activeCount = 0;
  int _inactiveCount = 0;

  String _statusFilter = 'All';
  String _employmentTypeFilter = 'All';

  bool get _hasActiveFilters =>
      _statusFilter != 'All' || _employmentTypeFilter != 'All';

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _loadStats();
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

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _staffApiService.getStaffList(status: 'active', page: 1, perPage: 1),
        _staffApiService.getStaffList(status: 'inactive', page: 1, perPage: 1),
      ]);
      if (!mounted) return;
      setState(() {
        _activeCount = results[0].total;
        _inactiveCount = results[1].total;
      });
    } catch (_) {
      // Overview stats are non-critical — leave them as-is on failure.
    }
  }

  Future<void> _refresh() => Future.wait([_loadFirstPage(), _loadStats()]);

  void _onStatusTabChanged(String status) {
    setState(() => _statusFilter = status);
    _loadFirstPage();
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

  void _goToAddStaff() {
    NavigationUtils.push(const CreateStaffScreen(), context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              ResponsiveUtils.screenPadding(context) +
              const EdgeInsets.only(top: AppSpacing.md),
          child: _buildStatsRow(context),
        ),
        _buildToolbar(context),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final totalCount = _activeCount + _inactiveCount;

    final cards = [
      _StatCard(
        label: 'TOTAL STAFF',
        value: '$totalCount',
        caption: 'All Team Members',
        icon: Icons.groups_outlined,
        iconBackground: AppColors.surfaceHighlight,
        iconColor: AppColors.primary,
      ),
      _StatCard(
        label: 'ACTIVE STAFF',
        value: '$_activeCount',
        caption: 'Currently Working',
        icon: Icons.check_circle_outline,
        iconBackground: AppColors.onDutyBackground,
        iconColor: AppColors.onDutyText,
      ),
      _StatCard(
        label: 'INACTIVE STAFF',
        value: '$_inactiveCount',
        caption: 'Not Active',
        icon: Icons.person_off_outlined,
        iconBackground: AppColors.offDutyBackground,
        iconColor: AppColors.offDutyText,
      ),
    ];

    if (ResponsiveUtils.isMobile(context)) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding:
          ResponsiveUtils.screenPadding(context) +
          const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              ElevatedButton.icon(
                onPressed: _goToAddStaff,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add Staff'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'All (${_activeCount + _inactiveCount})',
                        selected: _statusFilter == 'All',
                        onTap: () => _onStatusTabChanged('All'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _TabChip(
                        label: 'Active ($_activeCount)',
                        selected: _statusFilter == 'Active',
                        onTap: () => _onStatusTabChanged('Active'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _TabChip(
                        label: 'Inactive ($_inactiveCount)',
                        selected: _statusFilter == 'Inactive',
                        onTap: () => _onStatusTabChanged('Inactive'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _employmentTypeFilter,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                  items: [
                    for (final option in _employmentTypeOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option == 'All' ? 'All Types' : option),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _employmentTypeFilter = value);
                    _loadFirstPage();
                  },
                ),
              ),
            ],
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

    final columns = ResponsiveUtils.value<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    final rows = <List<Staff>>[];
    for (var i = 0; i < _items.length; i += columns) {
      rows.add(_items.skip(i).take(columns).toList());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding:
            ResponsiveUtils.screenPadding(context) +
            const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i != 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: i < row.length
                            ? _StaffCard(staff: row[i], onChanged: _refresh)
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          _buildFooter(),
        ],
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
  const _StaffCard({required this.staff, required this.onChanged});

  final Staff staff;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = staff.status == 'active';

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _showStaffDetail(context, staff),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                staff.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMd(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _staffCodeBadge(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          staff.jobTitle != null && staff.jobTitle!.isNotEmpty
                              ? staff.jobTitle!
                              : staff.employmentType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Joining Date',
                          style: AppTypography.labelSm(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeUtils.formatApiDate(staff.joiningDate),
                          style: AppTypography.labelLg(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift',
                            style: AppTypography.labelSm(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staff.shift?.name ?? 'Unassigned',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLg(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _statusChip(isActive),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        color: AppColors.surfaceHighlight,
        shape: BoxShape.circle,
      ),
      child: staff.profilePhotoUrl == null
          ? Text(
              initials,
              style: AppTypography.labelLg(color: AppColors.primary),
            )
          : Image.network(
              staff.profilePhotoUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text(
                initials,
                style: AppTypography.labelLg(color: AppColors.primary),
              ),
            ),
    );
  }

  Widget _staffCodeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.base),
      ),
      child: Text(
        staff.staffCode,
        style: AppTypography.labelSm(color: AppColors.textSecondary),
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
          const SizedBox(width: AppSpacing.xs),
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

  Future<void> _showStaffDetail(BuildContext context, Staff staff) async {
    await NavigationUtils.push(
      StaffProfileScreen(staff: staff),
      context: context,
    );
    onChanged();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSm(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTypography.displayLgMobile(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  caption,
                  style: AppTypography.bodySm(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLg(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
