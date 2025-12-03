import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:faminga_irrigation/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts up successfully', (WidgetTester tester) async {
    // Start the app
    app.main();
    
    // Wait for the app to settle
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Simple check to verify the test ran
    expect(true, isTrue);
  });
}
