// lib/models/assessment_result.dart

class AssessmentResult {
  final double accuracy;
  final double fluency;
  final double completeness;
  final Map<String, double> perWordAccuracy;
  final String provider;

  final String recognizedText; // Azure DisplayText
  final double score; // Weighted overall score

  // False when no provider was able to actually score the attempt (e.g. the
  // cloud assessor is unreachable). Callers must treat an ungraded result as
  // "try again" — never as a failed attempt — since accuracy/fluency/
  // completeness are meaningless placeholders (0) in that case, not a real
  // score of zero.
  final bool graded;

  AssessmentResult({
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.perWordAccuracy,
    required this.provider,
    required this.recognizedText,
    this.graded = true,
  }) : score = (accuracy * 0.6) + (fluency * 0.2) + (completeness * 0.2);
}
