import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readright_app/screens/feedback_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // REQUIRED so LocalProgressService does not hang forever
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FeedbackScreen shows empty placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FeedbackScreen(studentId: 'abc')),
    );

    // Let async loadLatest() finish
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Great Job!'), findsOneWidget);
  });
}
