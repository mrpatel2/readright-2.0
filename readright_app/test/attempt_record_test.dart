import 'package:flutter_test/flutter_test.dart';
import 'package:readright_app/models/attempt_record.dart';

void main() {
  test("AttemptRecord serializes and deserializes correctly", () {
    final record = AttemptRecord(
      word: "motor",
      listName: "TestList",
      correct: true,
      timestamp: DateTime(2025, 1, 1),
      accuracy: 90,
      fluency: 80,
      completeness: 70,
      recognizedText: "motor",
    );

    final json = record.toJson();
    final restored = AttemptRecord.fromJson(json);

    expect(restored.word, "motor");
    expect(restored.listName, "TestList");
    expect(restored.correct, true);
    expect(restored.accuracy, 90);
    expect(restored.recognizedText, "motor");
  });
}
