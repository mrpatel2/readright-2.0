import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readright_app/models/word_item.dart';
import 'package:readright_app/services/fill_blank_service.dart';

void main() {
  final pool = [
    WordItem(
      category: 'Dolch',
      word: 'all',
      exampleSentence: 'All the kids are here.',
    ),
    WordItem(category: 'Dolch', word: 'am', exampleSentence: 'I am ready.'),
    WordItem(category: 'Dolch', word: 'are', exampleSentence: 'We are happy.'),
    WordItem(
      category: 'Dolch',
      word: 'brown',
      exampleSentence: 'The dog is brown.',
    ),
  ];

  test('round options always include the target word exactly once', () {
    final service = FillBlankService(random: Random(1));
    final round = service.buildRound(pool, pool.first);

    expect(round.options.where((o) => o == 'all').length, 1);
  });

  test(
    'round options never exceed requested count and never include duplicates',
    () {
      final service = FillBlankService(random: Random(2));
      final round = service.buildRound(pool, pool[1], optionCount: 4);

      expect(round.options.length, lessThanOrEqualTo(4));
      expect(round.options.toSet().length, round.options.length);
    },
  );

  test(
    'sentence has the target word replaced with a blank, case-insensitively',
    () {
      final service = FillBlankService(random: Random(3));
      final round = service.buildRound(pool, pool.first);

      expect(round.sentenceWithBlank, isNot(contains('All')));
      expect(round.sentenceWithBlank, contains('____'));
    },
  );

  test(
    'falls back to appending a blank when the word is not found verbatim in the sentence',
    () {
      final oddball = WordItem(
        category: 'Dolch',
        word: 'zzz',
        exampleSentence: 'No match here.',
      );
      final service = FillBlankService(random: Random(4));
      final round = service.buildRound(pool, oddball);

      expect(round.sentenceWithBlank, 'No match here. ____');
    },
  );

  test('gracefully handles a pool smaller than the requested option count', () {
    final tinyPool = [pool.first];
    final service = FillBlankService(random: Random(5));
    final round = service.buildRound(tinyPool, pool.first, optionCount: 4);

    expect(round.options, ['all']);
  });
}
