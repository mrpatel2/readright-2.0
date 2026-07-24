// lib/models/word_item.dart
//
// Represents a single practice word for ReadRight
// Includes mastery tracking for local persistence.

class WordItem {
  final String category;
  final String word;
  final String exampleSentence;
  bool mastered;

  WordItem({
    required this.category,
    required this.word,
    required this.exampleSentence,
    this.mastered = false,
  });

  factory WordItem.fromCsv(List<String> parts) {
    return WordItem(
      category: parts[0],
      word: parts[1],
      exampleSentence: parts[2],
      mastered: parts.length > 3 ? parts[3].toLowerCase() == 'true' : false,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'word': word,
    'exampleSentence': exampleSentence,
    'mastered': mastered,
  };

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      category: json['category'],
      word: json['word'],
      exampleSentence: json['exampleSentence'],
      mastered: json['mastered'] ?? false,
    );
  }
}
