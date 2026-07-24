import 'package:flutter_test/flutter_test.dart';
import 'package:readright_app/services/word_timing_service.dart';

void main() {
  final timing = WordTimingService();

  group('syllableCount', () {
    test('short words are one syllable', () {
      expect(timing.syllableCount('the'), 1);
      expect(timing.syllableCount('at'), 1);
    });

    test('longer words count multiple vowel groups', () {
      expect(timing.syllableCount('beautiful'), 3);
      expect(timing.syllableCount('elephant'), 3);
    });

    test('silent trailing e does not add a syllable', () {
      expect(timing.syllableCount('ate'), 1);
      expect(timing.syllableCount('like'), 1);
    });

    test('empty input never returns fewer than one syllable', () {
      expect(timing.syllableCount(''), 1);
    });
  });

  group('recordingDurationFor', () {
    test('longer words get a longer window than short words', () {
      final shortWordDuration = timing.recordingDurationFor('the');
      final longWordDuration = timing.recordingDurationFor('beautiful');

      expect(longWordDuration, greaterThan(shortWordDuration));
    });

    test('duration is always clamped within a sane range', () {
      for (final word in ['a', 'the', 'beautiful', 'extraordinarily', '']) {
        final duration = timing.recordingDurationFor(word);
        expect(
          duration,
          greaterThanOrEqualTo(const Duration(milliseconds: 1800)),
        );
        expect(duration, lessThanOrEqualTo(const Duration(milliseconds: 5200)));
      }
    });
  });
}
