import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ben/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders Ben splash screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BenApp());
    expect(find.text('BEN'), findsOneWidget);
    // Settle the splash navigation timer
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
