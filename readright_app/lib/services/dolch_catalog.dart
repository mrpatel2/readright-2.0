// lib/services/dolch_catalog.dart
//
// Grade-level Dolch lists for the AI Story Builder, keyed the same way as
// the backend proxy's ALLOWED_GRADE_LEVELS (see backend/server.js) so the
// teacher's dropdown selection maps directly onto the API contract.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/word_item.dart';

class DolchLevel {
  final String key; // must match backend/server.js ALLOWED_GRADE_LEVELS
  final String label;
  final String assetPath;

  const DolchLevel({
    required this.key,
    required this.label,
    required this.assetPath,
  });
}

const List<DolchLevel> dolchLevels = [
  DolchLevel(key: 'prek', label: 'Pre-K', assetPath: 'lib/data/dolch_prek.csv'),
  DolchLevel(
    key: 'kindergarten',
    label: 'Kindergarten',
    assetPath: 'lib/data/dolch_kindergarten.csv',
  ),
  DolchLevel(
    key: '1st',
    label: '1st Grade',
    assetPath: 'lib/data/dolch_1st.csv',
  ),
  DolchLevel(
    key: '2nd',
    label: '2nd Grade',
    assetPath: 'lib/data/dolch_2nd.csv',
  ),
  DolchLevel(
    key: '3rd',
    label: '3rd Grade',
    assetPath: 'lib/data/dolch_3rd.csv',
  ),
];

class DolchCatalog {
  /// Loads the full word list for a grade-level CSV, unfiltered by any
  /// student's mastery progress — the teacher is picking a level to
  /// generate content for, not resuming a student's practice session.
  static Future<List<WordItem>> loadWords(String assetPath) async {
    final csv = await rootBundle.loadString(assetPath);
    final lines = const LineSplitter().convert(csv);
    final words = <WordItem>[];

    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 3) continue;
      words.add(
        WordItem(category: parts[0], word: parts[1], exampleSentence: parts[2]),
      );
    }
    return words;
  }
}
