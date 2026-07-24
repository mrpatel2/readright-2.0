// lib/services/story_repository.dart
//
// Firestore persistence for generated stories. Mirrors the
// teachers/{teacherId}/classes/{classId}/... shape StudentRepository uses,
// so story content lives alongside the roster it was generated for.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story_record.dart';

class StoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _storiesCol({
    required String teacherId,
    required String classId,
  }) {
    return _db
        .collection('teachers')
        .doc(teacherId)
        .collection('classes')
        .doc(classId)
        .collection('stories');
  }

  Future<StoryRecord> saveStory({
    required String teacherId,
    required String classId,
    required String studentId,
    required String studentName,
    required String gradeLevel,
    required String? theme,
    required List<String> words,
    required String story,
  }) async {
    final col = _storiesCol(teacherId: teacherId, classId: classId);
    final data = {
      'studentId': studentId,
      'studentName': studentName,
      'gradeLevel': gradeLevel,
      'theme': theme,
      'words': words,
      'story': story,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final docRef = await col.add(data);

    return StoryRecord(
      id: docRef.id,
      studentId: studentId,
      studentName: studentName,
      gradeLevel: gradeLevel,
      theme: theme,
      words: words,
      story: story,
      createdAt: DateTime.now(),
    );
  }

  /// Most recent stories for one student, newest first.
  Future<List<StoryRecord>> getStoriesForStudent({
    required String teacherId,
    required String classId,
    required String studentId,
    int limit = 10,
  }) async {
    final snap = await _storiesCol(teacherId: teacherId, classId: classId)
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map(StoryRecord.fromDoc).toList();
  }
}
