import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows Pathok onboarding', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const PathokApp());
    await tester.pumpAndSettle();
    expect(find.text('শুরু করুন'), findsOneWidget);
  });
}
