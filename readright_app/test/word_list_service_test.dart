// test/word_list_service_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readright_app/services/word_list_service.dart';
import 'package:readright_app/services/local_progress_service.dart';
import 'package:readright_app/models/word_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fresh in-memory SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});

    // Clear any previous mock handlers to avoid bleed-over between tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test(
    'WordListService loads list from CSV and marks mastered words correctly',
    () async {
      // === 1. Mock CSV file content ===
      const mockCsv = '''
category,word,example
animal,cat,The cat ran.
animal,dog,The dog barked.
''';

      // === 2. Mock rootBundle asset loading ===
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            if (message == null) return null;

            // Asset key is sent as raw UTF-8 bytes
            final key = utf8.decode(message.buffer.asUint8List());

            if (key == 'lib/data/test1.csv') {
              final bytes = utf8.encode(mockCsv);
              final uint8list = Uint8List.fromList(bytes);
              return ByteData.view(uint8list.buffer);
            }

            // Return null for any other asset (acts like "not found")
            return null;
          });

      // === 3. Prepare LocalProgressService and WordListService ===
      final storage = LocalProgressService(studentId: 'abc123');

      // Make index = 0 so it loads "lib/data/test1.csv"
      await storage.setCurrentListIndex(0);

      // Mark "dog" as mastered so the test can verify mastered flag works
      await storage.markWordMastered('dog');

      final service = WordListService(storage);

      // === 4. Load list ===
      final List<WordItem> items = await service.loadCurrentList();

      // === 5. Assertions ===
      expect(items.length, 2);

      expect(items[0].word, 'cat');
      expect(items[0].mastered, false); // cat is NOT mastered

      expect(items[1].word, 'dog');
      expect(items[1].mastered, true); // dog WAS mastered

      expect(items[0].exampleSentence, 'The cat ran.');
      expect(items[1].exampleSentence, 'The dog barked.');
    },
  );
}
