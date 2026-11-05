import 'package:flutter_test/flutter_test.dart';

import 'package:staff_attendance/main.dart';

void main() {
  testWidgets('App renders the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Spicera Workforce'), findsOneWidget);
    expect(find.text('Attendance & Payroll, Simplified'), findsOneWidget);
  });
}
