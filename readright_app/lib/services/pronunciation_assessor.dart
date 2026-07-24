// lib/services/pronunciation_assessor.dart
//
// This file defines the core abstraction for pronunciation assessment.
// As per the assignment, this allows us to swap between different providers
// (e.g., a local fallback and a cloud-based service).

import 'dart:typed_data';
import '../models/assessment_result.dart';

/// Abstract class (interface) for any pronunciation assessment provider.
///
/// Implementations should take:
///  - referenceText: the expected passage/word the student is reading
///  - audioBytes: a 16-bit WAV buffer (e.g., from SpeechService.recordAudio())
///  - locale: BCP-47 language tag like "en-US"
///
/// and return an AssessmentResult with accuracy/fluency/completeness and
/// per-word scores filled in as best they can.
abstract class PronunciationAssessor {
  Future<AssessmentResult> assess({
    required String referenceText,
    required Uint8List audioBytes,
    String locale = 'en-US',
  });
}

/// Simple mock assessor for offline testing / development.
///
/// This does NOT call any cloud service. It just generates a fake score
/// based on the length of the reference text so the UI can be exercised.
class MockPronunciationAssessor implements PronunciationAssessor {
  @override
  Future<AssessmentResult> assess({
    required String referenceText,
    required Uint8List audioBytes,
    String locale = 'en-US',
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 750));

    // Very simple fake score: 0–100 based on text length
    final mockScore = ((referenceText.length * 7) % 101).toDouble();

    // Use the same value for all three high-level metrics
    final accuracy = mockScore;
    final fluency = mockScore;
    final completeness = mockScore;

    // Optionally assign the same score to each word
    final perWordAccuracy = <String, double>{};
    for (final word in referenceText.split(RegExp(r'\s+'))) {
      if (word.trim().isEmpty) continue;
      perWordAccuracy[word] = mockScore;
    }

    return AssessmentResult(
      accuracy: accuracy,
      fluency: fluency,
      completeness: completeness,
      perWordAccuracy: perWordAccuracy,
      provider: 'mock',
      recognizedText: "",
    );
  }
}
