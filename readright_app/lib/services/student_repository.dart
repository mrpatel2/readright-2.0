import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

class StudentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Firestore path helper
  CollectionReference<Map<String, dynamic>> _studentsCol({
    required String teacherId,
    required String classId,
  }) {
    return _db
        .collection('teachers')
        .doc(teacherId)
        .collection('classes')
        .doc(classId)
        .collection('students');
  }

  String _cacheKey(String classId) => 'class_${classId}_students';

  /// Hybrid: Firestore first, fallback to local cache
  Future<List<Student>> getStudents({
    required String teacherId,
    required String classId,
  }) async {
    try {
      final snap = await _studentsCol(
        teacherId: teacherId,
        classId: classId,
      ).orderBy('name').get();

      final students = snap.docs.map(Student.fromDoc).map((s) {
        // SANITIZE PIN (Firestore may return null)
        return s.copyWith(pin: s.pin ?? "");
      }).toList();

      // Cache locally
      await _saveCache(classId, students);
      return students;
    } catch (e) {
      // Offline → use cache
      return _loadFromCache(classId);
    }
  }

  /// Save cache locally
  Future<void> _saveCache(String classId, List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = students.map((s) => s.toJson()).toList();
    await prefs.setString(_cacheKey(classId), jsonEncode(jsonList));
  }

  /// Load from cache
  Future<List<Student>> _loadFromCache(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(classId));
    if (raw == null) return [];

    try {
      final List list = jsonDecode(raw);
      return list
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .map((s) => s.copyWith(pin: s.pin ?? "")) // sanitize
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a single student (Firestore + cache)
  Future<Student> addStudent({
    required String teacherId,
    required String classId,
    required String name,
    required String avatar,
    required String pin,
  }) async {
    final col = _studentsCol(teacherId: teacherId, classId: classId);

    final safePin = pin.trim();

    try {
      final docRef = await col.add({
        'name': name,
        'avatar': avatar,
        'pin': safePin, // NEVER null
        'isAudioRecordingEnabled': false,
      });

      final student = Student(
        id: docRef.id,
        name: name,
        avatar: avatar,
        pin: safePin,
      );

      // Update cache
      final existing = await _loadFromCache(classId);
      final updated = [...existing, student]
        ..sort((a, b) => a.name.compareTo(b.name));
      await _saveCache(classId, updated);

      return student;
    } catch (e) {
      // OFFLINE mode: local placeholder
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

      final student = Student(
        id: localId,
        name: name,
        avatar: avatar,
        pin: safePin,
      );

      final existing = await _loadFromCache(classId);
      final updated = [...existing, student]
        ..sort((a, b) => a.name.compareTo(b.name));
      await _saveCache(classId, updated);

      return student;
    }
  }

  /// Update an existing student (Firestore + cache)
  Future<void> updateStudent({
    required String studentId,
    required String teacherId,
    required String classId,
    required String name,
    required String avatar,
    required String pin,
    required bool isAudioRecordingEnabled,
  }) async {
    final col = _studentsCol(teacherId: teacherId, classId: classId);
    final safePin = pin.trim();

    // Try to update Firestore (may fail offline)
    try {
      await col.doc(studentId).update({
        'name': name,
        'avatar': avatar,
        'pin': safePin,
        'isAudioRecordingEnabled': isAudioRecordingEnabled,
      });
    } catch (_) {
      // Swallow Firestore error here; cache still updates below.
    }

    // Update local cache regardless (so offline edits still show up)
    final existing = await _loadFromCache(classId);

    bool found = false;
    final updated = existing.map((s) {
      if (s.id == studentId) {
        found = true;
        return s.copyWith(
          name: name,
          avatar: avatar,
          pin: safePin,
          isAudioRecordingEnabled: isAudioRecordingEnabled,
        );
      }
      return s;
    }).toList();

    // If the student wasn't in cache (edge case), add it
    if (!found) {
      updated.add(
        Student(
          id: studentId,
          name: name,
          avatar: avatar,
          pin: safePin,
          isAudioRecordingEnabled: isAudioRecordingEnabled,
        ),
      );
    }

    updated.sort((a, b) => a.name.compareTo(b.name));
    await _saveCache(classId, updated);
  }

  Future<void> deleteStudent({
    required String teacherId,
    required String classId,
    required String studentId,
  }) async {
    final col = _studentsCol(teacherId: teacherId, classId: classId);

    // Try deleting from Firestore (may fail offline)
    try {
      await col.doc(studentId).delete();
    } catch (_) {
      // ignore, offline mode
    }

    // Update cache always
    final existing = await _loadFromCache(classId);
    final updated = existing.where((s) => s.id != studentId).toList();
    await _saveCache(classId, updated);
  }

  /// Bulk import (students have no PIN by default)
  Future<List<Student>> importStudents({
    required String teacherId,
    required String classId,
    required List<String> names,
  }) async {
    final cleaned = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final List<Student> created = [];

    for (final name in cleaned) {
      final avatar = _avatarForName(name);
      final s = await addStudent(
        teacherId: teacherId,
        classId: classId,
        name: name,
        avatar: avatar,
        pin: "", // IMPORT = no PIN
      );
      created.add(s);
    }

    return created;
  }

  /// Deterministic avatar
  String _avatarForName(String name) {
    final avatars = [
      'tiger',
      'fox',
      'bear',
      'panda',
      'bunny',
      'frog',
      'lion',
      'cat',
      'dog',
    ];

    final index = name.hashCode.abs() % avatars.length;
    return avatars[index];
  }
}
