/// Scales the recording window to how long a word actually takes to say,
/// instead of the old fixed 3-second cap that cut off longer words mid-word
/// and scored the truncated recording as wrong. See PRD_Milestone2.md
/// section 3, item 2.
class WordTimingService {
  static const Duration _minDuration = Duration(milliseconds: 1800);
  static const Duration _maxDuration = Duration(milliseconds: 5200);
  static const Duration _basePerSyllable = Duration(milliseconds: 700);

  /// Rough vowel-group syllable estimate. Not linguistically perfect, but
  /// good enough to distinguish "the" from "beautiful" for timing purposes.
  int syllableCount(String word) {
    final normalized = word.trim().toLowerCase();
    if (normalized.isEmpty) return 1;

    final vowelGroups = RegExp(r'[aeiouy]+').allMatches(normalized).length;
    var count = vowelGroups;

    // Silent trailing "e" (e.g. "ate", "like") doesn't add a syllable.
    if (normalized.endsWith('e') && !normalized.endsWith('le') && count > 1) {
      count -= 1;
    }

    return count < 1 ? 1 : count;
  }

  /// Recording duration for [word], scaled by syllable count and clamped to
  /// a sane range so a single very long word can't hang the mic indefinitely.
  Duration recordingDurationFor(String word) {
    final syllables = syllableCount(word);
    final scaled =
        _basePerSyllable * syllables + const Duration(milliseconds: 1100);

    if (scaled < _minDuration) return _minDuration;
    if (scaled > _maxDuration) return _maxDuration;
    return scaled;
  }
}
