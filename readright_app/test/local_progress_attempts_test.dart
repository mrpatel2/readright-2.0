import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readright_app/services/local_progress_service.dart';
import 'package:readright_app/models/attempt_record.dart';

void main() {
  // Needed so plugin services & channels are available in tests
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // In-memory fake SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
  });

  test('LocalProgressService saves and loads attempts', () async {
    final service = LocalProgressService(studentId: 'test_student');

    final attempt = AttemptRecord(
      word: 'cat',
      accuracy: 90,
      fluency: 85,
      completeness: 95,
      recognizedText: 'cat',
      timestamp: DateTime.now(),
      correct: true,
      listName: "dolch_nouns",
    );

    await service.saveAttempt(attempt);

    final attempts = await service.getAttempts();

    expect(attempts.length, 1);
    expect(attempts.first.word, 'cat');
    expect(attempts.first.accuracy, 90);
  });
}
