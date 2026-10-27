import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ben/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders Ben splash screen and navigates to welcome smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BenApp());
    expect(find.text('BEN'), findsOneWidget);
    // After splash delay, transitions to Welcome screen
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Meet Ben.'), findsOneWidget);
  });
}
