// lib/screens/practice_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/word_item.dart';
import '../models/attempt_record.dart';

import '../services/speech_service.dart';
import '../services/word_list_service.dart';
import '../services/local_progress_service.dart';
import '../services/cloud_assessment_service.dart';
import '../services/student_session_service.dart';
import '../services/word_timing_service.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/record_placeholder.dart';
import '../widgets/star_burst.dart';

class PracticeScreen extends StatefulWidget {
  final String studentId;
  const PracticeScreen({super.key, required this.studentId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _showSuccess = false;
  late WordListService _wordListService;
  late SpeechService _speechService;
  late LocalProgressService _progressService;
  Student? _student;

  final CloudAssessmentService _cloud = CloudAssessmentService.instance;
  final WordTimingService _timing = WordTimingService();

  List<WordItem> _wordList = [];
  int _currentIndex = 0;

  bool _isLoading = true;
  bool _isRecording = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  @override
  void dispose() {
    try {
      _speechService.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initServices() async {
    _progressService = LocalProgressService(studentId: widget.studentId);
    _wordListService = WordListService(_progressService);
    _speechService = SpeechService();

    await _speechService.initialize();
    await _loadStudentProfile();
    await _loadWords();
  }

  Future<void> _loadStudentProfile() async {
    final student = await StudentSessionService.loadStudent();
    if (mounted) {
      setState(() {
        _student = student;
      });
    }
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

    if (words.isNotEmpty) {
      _findNextWord();
    }
  }

  Future<void> _resetProgress() async {
    await _progressService.setCurrentListIndex(0);
    await _progressService.clearMasteredWords();
    await _loadWords();
  }

  void _findNextWord() {
    final nextIndex = _wordList.indexWhere((w) => !w.mastered);

    if (nextIndex != -1) {
      setState(() => _currentIndex = nextIndex);
    } else {
      _completeList();
    }
  }

  void _skipWord() {
    if (_isRecording) return;

    int nextIndex =
    _wordList.indexWhere((w) => !w.mastered, _currentIndex + 1);

    if (nextIndex == -1) {
      nextIndex = _wordList.indexWhere((w) => !w.mastered);
    }

    setState(() {
      if (nextIndex != -1 && nextIndex != _currentIndex) {
        _currentIndex = nextIndex;
        _feedback = 'Skipped! Try this word instead. 👍';
      } else {
        _feedback = 'This is the last word!';
      }
    });
  }

  Future<void> _completeList() async {
    setState(() {
      _feedback = '🎉 List complete! Loading next list...';
      _isLoading = true;
    });

    await _wordListService.advanceToNextList();
    await Future.delayed(const Duration(seconds: 2));
    await _loadWords();
  }

  Future<void> _startPractice() async {
    if (_isRecording || _student == null) return;

    setState(() {
      _isRecording = true;
      _feedback = '';
    });

    final currentWord = _wordList[_currentIndex];

    final audioPath = await _speechService.recordAudio(
      studentId: widget.studentId,
      duration: _timing.recordingDurationFor(currentWord.word),
    );
    if (audioPath == null) {
      setState(() {
        _feedback = 'Recording failed. Try again! 🎤';
        _isRecording = false;
      });
      return;
    }

    final wavBytes = await File(audioPath).readAsBytes();

    final assessment = await _cloud.scoreAttempt(
      expectedWord: currentWord.word,
      recognizedWord: '',
      audioBytes: wavBytes,
    );

    // The assessor couldn't actually grade this attempt (e.g. Azure was
    // unreachable) — never turn that into a false "wrong". Let the student
    // retry for free instead of recording a failed attempt.
    if (!assessment.graded) {
      try {
        final file = File(audioPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      setState(() {
        _feedback = "We couldn't hear that clearly. Try again! 🎤";
        _isRecording = false;
      });
      return;
    }

    final score = assessment.score;
    final isCorrect = score >= 60;

    final bool shouldRetainAudio = _student!.isAudioRecordingEnabled;

    final attempt = AttemptRecord(
      word: currentWord.word,
      listName: currentWord.category,
      correct: isCorrect,
      timestamp: DateTime.now(),
      accuracy: assessment.accuracy,
      fluency: assessment.fluency,
      completeness: assessment.completeness,
      recognizedText: assessment.recognizedText,
      audioPath: shouldRetainAudio ? audioPath : null,
    );

    // Save to both services
    await _progressService.saveAttempt(attempt);
    await StudentSessionService.saveAttempt(widget.studentId, attempt);

    // Clean up audio file if not retained
    if (!shouldRetainAudio) {
      try {
        final file = File(audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Failed to delete non-retained audio file: $e');
      }
    }

    if (isCorrect) {
      setState(() {
        _feedback = '🌟 Excellent job! Well done!';
        currentWord.mastered = true;
        _showSuccess = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showSuccess = false);
      });

      await _progressService.markWordMastered(currentWord.word);
      await Future.delayed(const Duration(milliseconds: 300));

      await _speechService.speak([
        'Excellent job!',
        currentWord.word,
        currentWord.exampleSentence,
      ]);

      _findNextWord();
    } else {
      setState(() => _feedback = 'Keep trying! You can do it! 💪');
      await Future.delayed(const Duration(milliseconds: 300));

      await _speechService.speak([
        'Keep trying! You can do it!',
        currentWord.word,
        currentWord.exampleSentence,
      ]);
    }

    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotWidget(size: 100, animated: true),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            if (_feedback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _feedback,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    } else if (_wordList.isEmpty) {
      body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotWidget(size: 120, animated: true),
              const SizedBox(height: 24),
              const Icon(Icons.celebration_rounded,
                  size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                '🎉 Amazing Work! 🎉',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(color: Colors.orange.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ve mastered all the words!\nYou\'re a reading superstar! ⭐',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      final currentWord = _wordList[_currentIndex];

      body = SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // Word card - extra large and child-friendly
            Card(
              elevation: 8,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side:
                BorderSide(color: Colors.orange.shade300, width: 3),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(
                    vertical: 32.0, horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      'Your word is:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentWord.word,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Feedback message with animation
            AnimatedOpacity(
              opacity: _feedback.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _feedback.contains('Excellent') ||
                      _feedback.contains('🌟')
                      ? Colors.green.shade100
                      : _feedback.contains('Skipped')
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _feedback.contains('Excellent') ||
                        _feedback.contains('🌟')
                        ? Colors.green.shade300
                        : _feedback.contains('Skipped')
                        ? Colors.blue.shade300
                        : Colors.orange.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  _feedback,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _feedback.contains('Excellent') ||
                        _feedback.contains('🌟')
                        ? Colors.green.shade800
                        : _feedback.contains('Skipped')
                        ? Colors.blue.shade800
                        : Colors.orange.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tiger recording button
            RecordPlaceholder(
              isRecording: _isRecording,
              onTap: _startPractice,
            ),

            const SizedBox(height: 16),

            // Skip button - child-friendly
            OutlinedButton.icon(
              onPressed: _isRecording ? null : _skipWord,
              icon: const Icon(Icons.skip_next, size: 24),
              label: const Text('Skip This Word',
                  style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                side: BorderSide(
                    color: Colors.orange.shade300, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Stack(
      children: [
        body,
        // Success animation overlay
        if (_showSuccess)
          Positioned.fill(
            child: IgnorePointer(
              child: StarBurst(play: _showSuccess),
            ),
          ),
      ],
    );
  }
}
