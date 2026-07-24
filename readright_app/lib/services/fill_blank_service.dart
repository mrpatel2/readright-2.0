// lib/services/fill_blank_service.dart
//
// Pure round-building logic for the Fill the Blank Dolch game, kept
// separate from the screen so it's unit-testable without widget scaffolding.

import 'dart:math';

import '../models/word_item.dart';

class FillBlankRound {
  final WordItem target;
  final String sentenceWithBlank;
  final List<String> options;

  FillBlankRound({
    required this.target,
    required this.sentenceWithBlank,
    required this.options,
  });
}

class FillBlankService {
  final Random _random;

  FillBlankService({Random? random}) : _random = random ?? Random();

  /// Builds one round: [target]'s example sentence with the word blanked
  /// out, plus a shuffled multiple-choice list drawn from [pool] (other
  /// words from the same list stand in as distractors).
  FillBlankRound buildRound(
    List<WordItem> pool,
    WordItem target, {
    int optionCount = 4,
  }) {
    final distractors = pool
        .where((w) => w.word.toLowerCase() != target.word.toLowerCase())
        .toList()
      ..shuffle(_random);

    final options = <String>[
      target.word,
      ...distractors.take(optionCount - 1).map((w) => w.word),
    ]..shuffle(_random);

    return FillBlankRound(
      target: target,
      sentenceWithBlank: _blankOutWord(target.exampleSentence, target.word),
      options: options,
    );
  }

  String _blankOutWord(String sentence, String word) {
    final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
    if (!pattern.hasMatch(sentence)) return '$sentence ____';
    return sentence.replaceFirst(pattern, '____');
  }
}
