import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readright_app/services/local_progress_service.dart';

void main() {
  // Make sure plugin services are available for SharedPreferences mock
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Start each test with a fresh in-memory prefs store
    SharedPreferences.setMockInitialValues({});
  });

  test('Mastered words save & load correctly', () async {
    final service = LocalProgressService(studentId: 'student_1');

    // Mark two words as mastered
    await service.markWordMastered('cat');
    await service.markWordMastered('dog');

    // New instance to prove it really persisted
    final serviceAgain = LocalProgressService(studentId: 'student_1');

    // Assuming LocalProgressService exposes a way to check mastered words.
    // If the method name is slightly different in your code, adjust here.
    final isCatMastered = await serviceAgain.isWordMastered('cat');
    final isDogMastered = await serviceAgain.isWordMastered('dog');
    final isBirdMastered = await serviceAgain.isWordMastered('bird');

    expect(isCatMastered, isTrue);
    expect(isDogMastered, isTrue);
    expect(isBirdMastered, isFalse);
  });

  test('Mastered words clear', () async {
    final service = LocalProgressService(studentId: 'student_1');

    await service.markWordMastered('pizza');

    var isPizzaMastered = await service.isWordMastered('pizza');
    expect(isPizzaMastered, isTrue);

    // Clear all mastered words
    await service.clearMasteredWords();

    // New instance to ensure it was actually cleared from storage
    final serviceAgain = LocalProgressService(studentId: 'student_1');
    isPizzaMastered = await serviceAgain.isWordMastered('pizza');

    expect(isPizzaMastered, isFalse);
  });
}
