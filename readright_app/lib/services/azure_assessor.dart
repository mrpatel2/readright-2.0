// lib/services/azure_assessor.dart
//
// Azure Pronunciation Assessment implementation that works with
// SpeechService.recordAudio() (WAV bytes) and returns your
// models/AssessmentResult. It also implements PronunciationAssessor
// so you can swap providers.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/assessment_result.dart';
import 'pronunciation_assessor.dart';

class AzureAssessor implements PronunciationAssessor {
  final String _region =
      dotenv.env['AZURE_SPEECH_REGION'] ??
      dotenv.env['AZURE_REGION'] ??
      'eastus';

  final String _key =
      dotenv.env['AZURE_SPEECH_KEY'] ?? dotenv.env['AZURE_KEY'] ?? '';

  Uri _buildUrl(String locale) {
    return Uri.parse(
      'https://$_region.stt.speech.microsoft.com/'
      'speech/recognition/conversation/cognitiveservices/v1'
      '?language=$locale&format=detailed',
    );
  }

  @override
  Future<AssessmentResult> assess({
    required String referenceText,
    required Uint8List audioBytes,
    String locale = 'en-US',
  }) async {
    if (_key.isEmpty) {
      throw Exception('[AzureAssessor] Missing AZURE_SPEECH_KEY.');
    }
    if (audioBytes.isEmpty) {
      throw Exception('[AzureAssessor] Audio buffer is empty.');
    }

    // Build Pronunciation Assessment config (REST requires Base64 JSON)
    final paConfig = {
      'referenceText': referenceText,
      'gradingSystem': 'HundredMark',
      'granularity': 'Phoneme',
      'enableMiscue': true,
      'dimension': 'Comprehensive',
    };

    final paHeader = base64Encode(utf8.encode(jsonEncode(paConfig)));

    // Send audio to Azure
    final response = await http.post(
      _buildUrl(locale),
      headers: {
        'Ocp-Apim-Subscription-Key': _key,
        'Pronunciation-Assessment': paHeader,
        'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
        'Accept': 'application/json',
      },
      body: audioBytes,
    );

    // Debugging
    // (You can comment these out in production)
    print("🔵 RAW STATUS: ${response.statusCode}");
    print("🔵 RAW HEADERS: ${response.headers}");
    print("🔵 RAW BODY:\n${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
        "[AzureAssessor] HTTP ${response.statusCode}: ${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    // Helper to safely parse numbers from JSON
    double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

    // ------------------------------------------------------------------
    // 1) Handle the "nothing recognized" case more gracefully
    // ------------------------------------------------------------------
    final nbestList = (data['NBest'] as List?);

    if (nbestList == null || nbestList.isEmpty) {
      // Try to fall back to DisplayText if Azure gave us *some* text.
      final rawDisplay = (data['DisplayText'] ?? "").toString().trim();

      if (rawDisplay.isNotEmpty) {
        // Compute similarity-based score from expected vs. recognized string.
        final sim = _stringSimilarity(referenceText, rawDisplay);
        final score = _clampScore(sim * 100.0);

        return AssessmentResult(
          accuracy: score,
          fluency: score,
          completeness: score,
          perWordAccuracy: {referenceText: score},
          provider: 'azure',
          recognizedText: rawDisplay,
        );
      }

      // Truly nothing recognized → this really is a "0" case.
      return AssessmentResult(
        accuracy: 0,
        fluency: 0,
        completeness: 0,
        perWordAccuracy: const {},
        provider: 'azure',
        recognizedText: "",
      );
    }

    // ------------------------------------------------------------------
    // 2) Normal case: Azure returns at least one NBest hypothesis
    // ------------------------------------------------------------------
    final nbest = nbestList.first;

    final rawAccuracy = _num(nbest['AccuracyScore']); // 0–100
    final rawFluency = _num(nbest['FluencyScore']); // 0–100
    final rawCompleteness = _num(nbest['CompletenessScore']); // 0–100
    final pronScore = _num(nbest['PronScore']); // 0–100 (unused but available)

    // Per-word scoring
    final perWordAccuracy = <String, double>{};
    final words = (nbest['Words'] as List?) ?? const [];

    for (final w in words) {
      final wordText = (w['Word'] ?? '').toString();
      if (wordText.isEmpty) continue;

      final wScore = _num(w['AccuracyScore']);
      perWordAccuracy[wordText] = _clampScore(wScore);
    }

    // Azure recognized text (what it thinks was said)
    final recognized = (data['DisplayText'] ?? nbest['Display'] ?? "")
        .toString();

    // ------------------------------------------------------------------
    // 3) Blend Azure’s accuracy with a string-similarity score so
    //    wrong-but-close attempts don’t drop straight to 0.
    // ------------------------------------------------------------------
    final sim = _stringSimilarity(referenceText, recognized);
    // Weighted blend:
    //  - 70% Azure’s PA accuracy
    //  - up to +30 points from string similarity
    final blendedAccuracy = _clampScore(0.7 * rawAccuracy + 30.0 * sim);

    // For fluency/completeness we keep Azure’s values, but clamped
    final finalFluency = _clampScore(rawFluency);
    final finalCompleteness = _clampScore(rawCompleteness);

    return AssessmentResult(
      accuracy: blendedAccuracy,
      fluency: finalFluency,
      completeness: finalCompleteness,
      perWordAccuracy: perWordAccuracy,
      provider: 'azure',
      recognizedText: recognized,
    );
  }

  // ==================================================================
  // Helper functions: text normalization, Levenshtein, similarity, clamp
  // ==================================================================

  String _normalizeText(String input) {
    // Lowercase, trim, and strip simple punctuation
    final lowered = input.toLowerCase().trim();
    final cleaned = lowered.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return cleaned;
  }

  /// Normalized Levenshtein distance → similarity in [0, 1].
  /// 1.0 = identical, 0.0 = completely different.
  double _stringSimilarity(String a, String b) {
    final s = _normalizeText(a);
    final t = _normalizeText(b);

    if (s.isEmpty && t.isEmpty) return 1.0;
    if (s.isEmpty || t.isEmpty) return 0.0;

    final dist = _levenshtein(s, t);
    final maxLen = s.length > t.length ? s.length : t.length;
    return (maxLen == 0) ? 1.0 : (1.0 - dist / maxLen);
  }

  int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;

    if (m == 0) return n;
    if (n == 0) return m;

    // DP matrix of size (m+1) x (n+1)
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;

        dp[i][j] = [
          dp[i - 1][j] + 1, // deletion
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[m][n];
  }

  double _clampScore(double v) {
    if (v < 0) return 0;
    if (v > 100) return 100;
    return v;
  }
}
