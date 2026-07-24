import '../models/assessment_result.dart';

import 'dart:typed_data';
import 'pronunciation_assessor.dart';

/// Used whenever the cloud assessor (Azure) can't be reached or returns
/// nothing usable — a flaky classroom Wi-Fi connection, a timeout, a 5xx.
///
/// Previously this returned a hardcoded 0/100 "accuracy", which is
/// indistinguishable from an actual mispronunciation: a child on bad Wi-Fi
/// got told "you got it wrong" for a network blip, not "try again". Since we
/// have no on-device speech recognizer to fall back on, the only honest
/// response is to say we couldn't grade the attempt at all — `graded: false`
/// — and let the caller offer a free retry instead of penalizing the
/// student. See PRD_Milestone2.md section 3, item 1.
class CloudFallbackAssessor implements PronunciationAssessor {
  @override
  Future<AssessmentResult> assess({
    required String referenceText,
    required Uint8List audioBytes,
    String locale = 'en-US',
  }) async {
    return AssessmentResult(
      recognizedText: "",
      accuracy: 0,
      fluency: 0,
      completeness: 0,
      perWordAccuracy: const {},
      provider: "fallback",
      graded: false,
    );
  }
}
