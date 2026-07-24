// lib/services/student_session_service.dart
//
// Stores and restores the currently-selected student on the device
// so that Practice / Feedback / Progress can all know "who is using
// the app" without needing a password login.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/attempt_record.dart';

class StudentSessionService {
  static const _studentKey = 'current_student';
  static const _attemptsKeyPrefix = 'student_attempts_';

  /// Save full student object locally as JSON.
  static Future<void> saveStudent(Student s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentKey, jsonEncode(s.toJson()));
  }

  /// Load the currently-selected student, or null if none set yet.
  static Future<Student?> loadStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studentKey);
    if (raw == null) return null;
    return Student.fromJson(jsonDecode(raw));
  }

  /// Clear the active student (e.g., when a teacher logs out or switches).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_studentKey);
  }

  // --- ATTEMPT RECORD MANAGEMENT ---

  static String _getAttemptsCacheKey(String studentId) =>
      '$_attemptsKeyPrefix$studentId';

  /// Save a student's reading attempt locally, keeping the last 10 within 30 days.
  static Future<void> saveAttempt(
    String studentId,
    AttemptRecord attempt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getAttemptsCacheKey(studentId);

    // Get existing attempts and add the new one
    final existing = await getAttemptsForStudent(studentId);
    final updated = [attempt, ...existing];

    // Filter out attempts older than 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recent = updated
        .where((a) => a.timestamp.isAfter(thirtyDaysAgo))
        .toList();

    // Sort by most recent first
    recent.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Keep only the top 10
    final capped = recent.take(10).toList();

    // Save back to storage
    final jsonList = capped.map((a) => a.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  /// Load attempts from local cache for a specific student.
  static Future<List<AttemptRecord>> getAttemptsForStudent(
    String studentId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getAttemptsCacheKey(studentId);
    final raw = prefs.getString(key);

    if (raw == null) return [];

    try {
      final List list = jsonDecode(raw);
      return list
          .map((e) => AttemptRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading attempts from cache for student $studentId: $e');
      return [];
    }
  }
}
