// test/test_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> setupTestEnv() async {
  // No file I/O, just inject test values directly
  dotenv.testLoad(
    fileInput: '''
AZURE_KEY=test_key
AZURE_REGION=test_region
''',
  );
}
