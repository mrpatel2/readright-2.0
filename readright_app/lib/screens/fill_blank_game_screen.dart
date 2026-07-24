// lib/screens/fill_blank_game_screen.dart
//
// Dolch "Fill the Blank" game — the P0 sight-word game for M3 (Pillar 3).
// Reuses the same word progression, mastery tracking, and AttemptRecord
// model as PracticeScreen so a word mastered here counts the same as one
// mastered by pronunciation practice. See PRD_Milestone2.md section 1.

import 'package:flutter/material.dart';

import '../models/word_item.dart';
import '../models/attempt_record.dart';
import '../services/word_list_service.dart';
import '../services/local_progress_service.dart';
import '../services/student_session_service.dart';
import '../services/speech_service.dart';
import '../services/fill_blank_service.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/star_burst.dart';

class FillBlankGameScreen extends StatefulWidget {
  final String studentId;
  const FillBlankGameScreen({super.key, required this.studentId});

  @override
  State<FillBlankGameScreen> createState() => _FillBlankGameScreenState();
}

class _FillBlankGameScreenState extends State<FillBlankGameScreen> {
  late WordListService _wordListService;
  late LocalProgressService _progressService;
  final SpeechService _speechService = SpeechService();
  final FillBlankService _gameService = FillBlankService();

  List<WordItem> _wordList = [];
  FillBlankRound? _round;

  bool _isLoading = true;
  bool _showSuccess = false;
  String? _selectedOption;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _progressService = LocalProgressService(studentId: widget.studentId);
    _wordListService = WordListService(_progressService);
    await _speechService.initialize();
    await _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _feedback = '';
    });

    final words = await _wordListService.loadCurrentList();
    setState(() {
      _wordList = words;
      _isLoading = false;
    });

    if (words.isNotEmpty) _nextRound();
  }

  void _nextRound() {
    final nextIndex = _wordList.indexWhere((w) => !w.mastered);
    if (nextIndex == -1) {
      setState(() => _round = null);
      return;
    }
    setState(() {
      _round = _gameService.buildRound(_wordList, _wordList[nextIndex]);
      _selectedOption = null;
      _feedback = '';
    });
  }

  Future<void> _choose(String option) async {
    final round = _round;
    if (round == null || _selectedOption != null) return;

    final isCorrect = option.toLowerCase() == round.target.word.toLowerCase();
    setState(() {
      _selectedOption = option;
      _feedback = isCorrect
          ? '🌟 Correct!'
          : 'Not quite — the word was "${round.target.word}"';
    });

    final attempt = AttemptRecord(
      word: round.target.word,
      listName: round.target.category,
      correct: isCorrect,
      timestamp: DateTime.now(),
      accuracy: isCorrect ? 100 : 0,
      fluency: isCorrect ? 100 : 0,
      completeness: isCorrect ? 100 : 0,
      recognizedText: option,
      source: 'fill_blank',
    );

    await _progressService.saveAttempt(attempt);
    await StudentSessionService.saveAttempt(widget.studentId, attempt);

    if (isCorrect) {
      setState(() {
        round.target.mastered = true;
        _showSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showSuccess = false);
      });
      await _progressService.markWordMastered(round.target.word);
      await _speechService.speak(['Correct!', round.target.word]);
    } else {
      await _speechService.speak([
        'Not quite.',
        'The word was',
        round.target.word,
      ]);
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final stillUnmastered = _wordList.where((w) => !w.mastered).isNotEmpty;
    if (stillUnmastered) {
      _nextRound();
    } else {
      await _wordListService.advanceToNextList();
      await _loadWords();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_wordList.isEmpty || _round == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotWidget(size: 100, animated: true),
              const SizedBox(height: 16),
              Text(
                '🎉 All words mastered for now!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      final round = _round!;
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 6,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  round.sentenceWithBlank,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...round.options.map((option) {
              final isSelected = _selectedOption == option;
              final isTarget =
                  option.toLowerCase() == round.target.word.toLowerCase();
              Color? color;
              if (_selectedOption != null) {
                if (isTarget) {
                  color = Colors.green.shade100;
                } else if (isSelected) {
                  color = Colors.red.shade100;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedOption == null
                        ? () => _choose(option)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }),
            if (_feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _feedback,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _feedback.startsWith('🌟')
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        body,
        if (_showSuccess)
          Positioned.fill(
            child: IgnorePointer(child: StarBurst(play: _showSuccess)),
          ),
      ],
    );
  }
}
