// lib/models/attempt_record.dart
// Represents a single student's word attempt.
// Now supports full Azure scoring so feedback can show REAL scores.

class AttemptRecord {
  final String word;
  final String listName;
  final bool correct;
  final DateTime timestamp;
  final String? audioPath; // Path to the locally stored audio file

  // NEW — Azure scoring fields
  final double accuracy;
  final double fluency;
  final double completeness;
  final String recognizedText;

  // Which activity produced this attempt: pronunciation | fill_blank | story_reading.
  // See PRD_Milestone2.md section 2, data model.
  final String source;

  AttemptRecord({
    required this.word,
    required this.listName,
    required this.correct,
    required this.timestamp,
    this.audioPath,

    // Defaults for backward compatibility
    this.accuracy = 0,
    this.fluency = 0,
    this.completeness = 0,
    this.recognizedText = "",
    this.source = "pronunciation",
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'listName': listName,
    'correct': correct,
    'timestamp': timestamp.toIso8601String(),
    'audioPath': audioPath,

    // NEW fields
    'accuracy': accuracy,
    'fluency': fluency,
    'completeness': completeness,
    'recognizedText': recognizedText,
    'source': source,
  };

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    return AttemptRecord(
      word: json['word'],
      listName: json['listName'],
      correct: json['correct'],
      timestamp: DateTime.parse(json['timestamp']),
      audioPath: json['audioPath'],

      // Handle old records (null → default)
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      fluency: (json['fluency'] ?? 0).toDouble(),
      completeness: (json['completeness'] ?? 0).toDouble(),
      recognizedText: json['recognizedText'] ?? "",
      source: json['source'] ?? "pronunciation",
    );
  }
}
