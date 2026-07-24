import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readright_app/screens/practice_screen.dart';
import 'test_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Make sure dotenv has fake values before any widget is built
    await setupTestEnv();
  });

  setUp(() {
    // In-memory SharedPreferences for anything that uses it
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PracticeScreen shows loading mascot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PracticeScreen(studentId: '1')),
    );

    // Let the first frame build
    await tester.pump();

    // If your loading UI shows a spinner:
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // If instead your loading UI uses a MascotWidget or some other widget,
    // change the expectation to match that widget instead, e.g.:
    // expect(find.byType(MascotWidget), findsOneWidget);
  });
}
