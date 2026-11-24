import 'staff_model.dart';

class StaffListPage {
  const StaffListPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory StaffListPage.fromJson(Map<String, dynamic> json) {
    final staffJson = json['staff'] as List;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return StaffListPage(
      items: staffJson
          .map((item) => Staff.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }

  final List<Staff> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
