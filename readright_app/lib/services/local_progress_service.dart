// lib/services/local_progress_service.dart
//
// Handles per-student local storage for mastered words, attempts,
// list progression, and PDF exporting into the Android Downloads folder.

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/attempt_record.dart';

class LocalProgressService {
  final String studentId;

  LocalProgressService({required this.studentId});

  // Student-specific keys
  String get _keyMasteredWords => 'mastered_words_$studentId';
  String get _keyCurrentList => 'current_list_index_$studentId';
  String get _keyAttempts => 'attempt_records_$studentId';

  // ------------------------------------------------------------
  //                    ATTEMPT LOGGING
  // ------------------------------------------------------------

  Future<List<AttemptRecord>> getAttempts() => getAllAttempts();

  Future<List<AttemptRecord>> getAllAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsJson = prefs.getStringList(_keyAttempts) ?? [];

    return attemptsJson
        .map((json) => AttemptRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveAttempt(AttemptRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getStringList(_keyAttempts) ?? [];
    attempts.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_keyAttempts, attempts);
  }

  // ------------------------------------------------------------
  //                    MASTERED WORD LOGIC
  // ------------------------------------------------------------

  Future<Set<String>> _loadMasteredSet() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMasteredWords);
    if (raw == null) return {};

    try {
      return Set<String>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMasteredSet(Set<String> mastered) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMasteredWords, jsonEncode(mastered.toList()));
  }

  Future<bool> isWordMastered(String word) async {
    final mastered = await _loadMasteredSet();
    return mastered.contains(word.toLowerCase());
  }

  Future<void> markWordMastered(String word) async {
    final mastered = await _loadMasteredSet();
    mastered.add(word.toLowerCase());
    await _saveMasteredSet(mastered);
  }

  Future<List<String>> getAllMasteredWords() async {
    final mastered = await _loadMasteredSet();
    return mastered.toList();
  }

  Future<void> clearMasteredWords() async {
    await _saveMasteredSet({});
  }

  // ------------------------------------------------------------
  //                    LIST PROGRESSION
  // ------------------------------------------------------------

  Future<int> getCurrentListIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentList) ?? 0;
  }

  Future<void> setCurrentListIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentList, index);
  }

  // ------------------------------------------------------------
  //                       PDF EXPORT
  // ------------------------------------------------------------

  Future<String> exportAttemptsPDFToAndroidDownloads(
    DateTime start,
    DateTime end,
  ) async {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    final attempts = await getAllAttempts();

    // Filter date range
    final filtered = attempts.where((a) {
      return a.timestamp.isAfter(start) && a.timestamp.isBefore(end);
    }).toList();

    final pdf = pw.Document();

    int total = filtered.length;
    int correct = filtered.where((a) => a.correct).length;
    double accuracy = total == 0 ? 0 : (correct / total) * 100;

    // Build the PDF
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            "ReadRight – Student Progress Report",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text("Student ID: $studentId"),
          pw.Text("Date Range: ${df.format(start)} → ${df.format(end)}"),
          pw.SizedBox(height: 20),

          pw.Text(
            "Attempts:",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: ["Word", "List", "Correct", "Timestamp"],
            data: filtered
                .map(
                  (a) => [
                    a.word,
                    a.listName,
                    a.correct ? "Yes" : "No",
                    df.format(a.timestamp),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 25),
          pw.Text(
            "Summary:",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 8),

          pw.Text("Total Attempts: $total"),
          pw.Text("Correct: $correct"),
          pw.Text("Accuracy: ${accuracy.toStringAsFixed(1)}%"),
        ],
      ),
    );

    // Android Downloads folder
    final downloadsDir = await getExternalStorageDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = "attempts_${studentId}_$timestamp.pdf";

    final fullPath =
        "${downloadsDir!.parent.parent.parent.parent.path}/Download/$filename";

    final file = File(fullPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await pdf.save());

    return fullPath;
  }
}
