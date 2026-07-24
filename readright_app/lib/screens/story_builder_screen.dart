// lib/screens/story_builder_screen.dart
//
// The real AI Story Builder: teacher picks a student, a reading level, and
// an optional interest, then generates a Dolch-based story through the
// backend proxy. Generation only ever happens on explicit teacher action —
// see PRD_Milestone2.md section 5, "What stays human."

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/story_record.dart';
import '../models/word_item.dart';
import '../services/student_repository.dart';
import '../services/story_service.dart';
import '../services/story_repository.dart';
import '../services/dolch_catalog.dart';

class StoryBuilderScreen extends StatefulWidget {
  final String teacherId;
  final String classId;

  const StoryBuilderScreen({
    super.key,
    required this.teacherId,
    required this.classId,
  });

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  final _studentRepo = StudentRepository();
  final _storyService = StoryService();
  final _storyRepo = StoryRepository();
  final _themeController = TextEditingController();
  final _random = Random();

  List<Student> _students = [];
  bool _loadingStudents = true;

  Student? _selectedStudent;
  DolchLevel _selectedLevel = dolchLevels.first;

  bool _generating = false;
  bool _saving = false;
  String? _error;
  String? _story;
  List<String>? _storyWords;

  List<StoryRecord> _history = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final students = await _studentRepo.getStudents(
      teacherId: widget.teacherId,
      classId: widget.classId,
    );
    if (!mounted) return;
    setState(() {
      _students = students;
      _selectedStudent = students.isNotEmpty ? students.first : null;
      _loadingStudents = false;
    });
    if (_selectedStudent != null) _loadHistory();
  }

  Future<void> _loadHistory() async {
    final student = _selectedStudent;
    if (student == null) return;
    setState(() => _loadingHistory = true);
    try {
      final history = await _storyRepo.getStoriesForStudent(
        teacherId: widget.teacherId,
        classId: widget.classId,
        studentId: student.id,
      );
      if (!mounted) return;
      setState(() => _history = history);
    } catch (_) {
      // History is a convenience list; a failure here shouldn't block generation.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _generate() async {
    final student = _selectedStudent;
    if (student == null) return;

    setState(() {
      _generating = true;
      _error = null;
      _story = null;
    });

    try {
      final pool = await DolchCatalog.loadWords(_selectedLevel.assetPath);
      final words = _sampleWords(pool, 8);
      final theme = _themeController.text.trim();

      final story = await _storyService.generateStory(
        words: words,
        theme: theme.isEmpty ? null : theme,
        gradeLevel: _selectedLevel.key,
      );

      setState(() {
        _story = story;
        _storyWords = words;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  List<String> _sampleWords(List<WordItem> pool, int count) {
    final words = pool.map((w) => w.word).toList()..shuffle(_random);
    return words.take(count).toList();
  }

  Future<void> _saveStory() async {
    final student = _selectedStudent;
    final story = _story;
    final words = _storyWords;
    if (student == null || story == null || words == null) return;

    setState(() => _saving = true);
    try {
      await _storyRepo.saveStory(
        teacherId: widget.teacherId,
        classId: widget.classId,
        studentId: student.id,
        studentName: student.name,
        gradeLevel: _selectedLevel.key,
        theme: _themeController.text.trim().isEmpty ? null : _themeController.text.trim(),
        words: words,
        story: story,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story saved!')),
      );
      setState(() {
        _story = null;
        _storyWords = null;
      });
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save story: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Story Builder')),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Add students to your class first, then come back to build a story for them.'),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('For student', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Student>(
                        initialValue: _selectedStudent,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _students
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                            .toList(),
                        onChanged: (s) {
                          setState(() {
                            _selectedStudent = s;
                            _story = null;
                          });
                          _loadHistory();
                        },
                      ),
                      const SizedBox(height: 20),
                      Text('Reading level', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DolchLevel>(
                        initialValue: _selectedLevel,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: dolchLevels
                            .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                            .toList(),
                        onChanged: (l) => setState(() => _selectedLevel = l ?? _selectedLevel),
                      ),
                      const SizedBox(height: 20),
                      Text('Interest (optional)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _themeController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g. dinosaurs, soccer, outer space',
                          helperText: 'Every story is screened for age-appropriate content before it reaches a student.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generating ? null : _generate,
                          icon: _generating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_stories),
                          label: Text(_generating ? 'Generating…' : 'Generate story'),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade900)),
                        ),
                      ],
                      if (_story != null) ...[
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_story!, style: Theme.of(context).textTheme.bodyLarge),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: (_storyWords ?? [])
                                      .map((w) => Chip(label: Text(w)))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _saving ? null : _saveStory,
                                    icon: const Icon(Icons.save),
                                    label: Text(_saving ? 'Saving…' : 'Save story for ${_selectedStudent?.name ?? 'student'}'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Text('Previously saved stories', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_loadingHistory)
                        const Center(child: CircularProgressIndicator())
                      else if (_history.isEmpty)
                        Text('No stories saved for this student yet.',
                            style: Theme.of(context).textTheme.bodyMedium)
                      else
                        ..._history.map((h) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${h.gradeLevel}${h.theme != null ? ' • ${h.theme}' : ''}',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(h.story),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}
