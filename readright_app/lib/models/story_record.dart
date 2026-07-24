// lib/models/story_record.dart
//
// A single AI-generated story, owned at the ClassRoom level (teacher
// content, not student content — see PRD_Milestone2.md section 2).

import 'package:cloud_firestore/cloud_firestore.dart';

class StoryRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String gradeLevel;
  final String? theme;
  final List<String> words;
  final String story;
  final DateTime createdAt;

  StoryRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.gradeLevel,
    required this.theme,
    required this.words,
    required this.story,
    required this.createdAt,
  });

  static StoryRecord fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawTimestamp = data['createdAt'];

    return StoryRecord(
      id: doc.id,
      studentId: (data['studentId'] ?? '') as String,
      studentName: (data['studentName'] ?? '') as String,
      gradeLevel: (data['gradeLevel'] ?? '') as String,
      theme: data['theme'] as String?,
      words: List<String>.from(data['words'] as List? ?? const []),
      story: (data['story'] ?? '') as String,
      createdAt: rawTimestamp is Timestamp
          ? rawTimestamp.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'gradeLevel': gradeLevel,
    'theme': theme,
    'words': words,
    'story': story,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
