// lib/services/cloud_assessment_service.dart

import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/assessment_result.dart';
import 'azure_assessor.dart';
import 'cloud_fallback_assessor.dart';

class CloudAssessmentService extends ChangeNotifier {
  static final CloudAssessmentService instance =
      CloudAssessmentService._internal();
  factory CloudAssessmentService() => instance;
  CloudAssessmentService._internal();

  final AzureAssessor azure = AzureAssessor();
  final CloudFallbackAssessor fallback = CloudFallbackAssessor();

  AssessmentResult? lastResult;
  String? lastWord;

  Future<AssessmentResult> scoreAttempt({
    required String expectedWord,
    required String recognizedWord,
    required Uint8List audioBytes,
  }) async {
    // no audio → fallback immediately
    if (audioBytes.isEmpty || audioBytes.length < 2000) {
      final res = await fallback.assess(
        referenceText: expectedWord,
        audioBytes: audioBytes,
      );
      lastResult = res;
      lastWord = expectedWord;
      notifyListeners();
      return res;
    }

    try {
      // Azure first
      final res = await azure.assess(
        referenceText: expectedWord,
        audioBytes: audioBytes,
      );
      lastResult = res;
      lastWord = expectedWord;
      notifyListeners();
      return res;
    } catch (e) {
      // fallback
      final res = await fallback.assess(
        referenceText: expectedWord,
        audioBytes: audioBytes,
      );
      lastResult = res;
      lastWord = expectedWord;
      notifyListeners();
      return res;
    }
  }
}
