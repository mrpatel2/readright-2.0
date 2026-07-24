// lib/screens/student_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // Correct audio package

import '../models/attempt_record.dart';
import '../services/student_session_service.dart';
import '../services/local_progress_service.dart';
import '../services/analytics_service.dart';

class StudentProgressScreen extends StatefulWidget {
  final String studentId;

  const StudentProgressScreen({super.key, required this.studentId});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  DateTime? _start;
  DateTime? _end;

  late LocalProgressService _progressService;
  final AnalyticsService _analyticsService = AnalyticsService();
  final DateFormat _df = DateFormat('yyyy-MM-dd');

  List<AttemptRecord> _recentAttempts = [];
  StudentAnalytics? _studentAnalytics;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _progressService = LocalProgressService(studentId: widget.studentId);
    _loadData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final attempts = await StudentSessionService.getAttemptsForStudent(
      widget.studentId,
    );
    final analytics = await _analyticsService.calculateStudentAnalytics(
      widget.studentId,
    );
    if (mounted) {
      setState(() {
        _recentAttempts = attempts;
        _studentAnalytics = analytics;
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio(String? path) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio recording found for this attempt.'),
        ),
      );
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      print("Error playing audio: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not play audio.')));
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _exportPDF() async {
    if (_start == null || _end == null) return;

    if (_end!.isBefore(_start!)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid Date Range"),
          content: const Text(
            "End date must be the same or after the start date.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final adjustedEnd = DateTime(
      _end!.year,
      _end!.month,
      _end!.day,
      23,
      59,
      59,
    );

    final path = await _progressService.exportAttemptsPDFToAndroidDownloads(
      _start!,
      adjustedEnd,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("PDF Export Complete"),
        content: Text(
          "Your PDF report has been saved to:\n\n$path\n\n"
          "Open your device's 'Download' folder to view it.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Progress")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_studentAnalytics != null)
                    _buildAnalyticsSection(_studentAnalytics!),
                  const SizedBox(height: 16),
                  const Text(
                    "Recent Attempts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _recentAttempts.isEmpty
                      ? const Text("No recent attempts found for this student.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentAttempts.length,
                          itemBuilder: (context, index) {
                            final attempt = _recentAttempts[index];
                            final hasAudio =
                                attempt.audioPath != null &&
                                attempt.audioPath!.isNotEmpty;
                            return Card(
                              child: ListTile(
                                title: Text(attempt.word),
                                subtitle: Text(
                                  DateFormat.yMMMd().add_jms().format(
                                    attempt.timestamp,
                                  ),
                                ),
                                trailing: hasAudio
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.play_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _playAudio(attempt.audioPath),
                                      )
                                    : const Icon(
                                        Icons.mic_off_outlined,
                                        color: Colors.grey,
                                      ),
                              ),
                            );
                          },
                        ),
                  const Divider(height: 32, thickness: 1),
                  const Text(
                    "Export Full History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("Start: "),
                      Expanded(
                        child: Text(
                          _start == null ? "Not set" : _df.format(_start!),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickStart,
                        child: const Text("Pick Start"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("End: "),
                      Expanded(
                        child: Text(
                          _end == null ? "Not set" : _df.format(_end!),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickEnd,
                        child: const Text("Pick End"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: (_start != null && _end != null)
                          ? _exportPDF
                          : null,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Export PDF to Downloads"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyticsSection(StudentAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overall Performance",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildStatCard(
              'Avg. Accuracy',
              '${analytics.averageAccuracy.toStringAsFixed(1)}%',
              Colors.blue,
            ),
            _buildStatCard(
              'Avg. Fluency',
              '${analytics.averageFluency.toStringAsFixed(1)}',
              Colors.green,
            ),
            _buildStatCard(
              'Avg. Completeness',
              '${analytics.averageCompleteness.toStringAsFixed(1)}%',
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Current List Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: analytics.totalWords > 0
              ? analytics.masteredWords / analytics.totalWords
              : 0,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 4),
        Text(
          '${analytics.masteredWords} of ${analytics.totalWords} words mastered',
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
