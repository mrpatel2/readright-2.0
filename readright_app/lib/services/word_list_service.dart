import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word_item.dart';
import 'local_progress_service.dart';

class WordListService {
  static const List<String> _dolchFiles = [
    'lib/data/test1.csv',
    'lib/data/test2.csv',
    'lib/data/dolch_prek.csv',
    //    'lib/data/dolch_kindergarten.csv',
    //    'lib/data/dolch_1st.csv',
    //    'lib/data/dolch_2nd.csv',
    //    'lib/data/dolch_3rd.csv',
    //    'lib/data/dolch_nouns.csv',
  ];

  final LocalProgressService storage;

  WordListService(this.storage);

  Future<List<WordItem>> loadCurrentList() async {
    int index = await storage.getCurrentListIndex();

    // If the index is out of bounds, it means the user has completed all lists.
    if (index >= _dolchFiles.length) {
      // Return an empty list to signal completion.
      return [];
    }

    final csv = await rootBundle.loadString(_dolchFiles[index]);
    final lines = const LineSplitter().convert(csv);
    final words = <WordItem>[];

    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 3) continue;
      words.add(
        WordItem(
          category: parts[0],
          word: parts[1],
          exampleSentence: parts[2],
          mastered: await storage.isWordMastered(parts[1]),
        ),
      );
    }
    return words;
  }

  Future<void> markWordMastered(String word) async {
    await storage.markWordMastered(word);
  }

  /// Increments the list index and clears progress for the next list.
  Future<void> advanceToNextList() async {
    int index = await storage.getCurrentListIndex();
    // Always increment the index. The loadCurrentList method will handle the out-of-bounds case.
    await storage.setCurrentListIndex(index + 1);
    await storage.clearMasteredWords();
  }
}
