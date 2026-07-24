// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import '../models/attempt_record.dart';
import '../services/local_progress_service.dart';
import '../widgets/mascot_widget.dart';

class FeedbackScreen extends StatefulWidget {
  final String studentId;
  const FeedbackScreen({super.key, required this.studentId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  AttemptRecord? _latest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    final progress = LocalProgressService(studentId: widget.studentId);
    final attempts = await progress.getAttempts();

    if (!mounted) return;

    setState(() {
      _latest = attempts.isNotEmpty ? attempts.last : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading spinner while we fetch from SharedPreferences
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
          ),
        ),
      );
    }

    final latest = _latest;

    // If no recording has been done yet for THIS student
    if (latest == null) {
      return Scaffold(
        backgroundColor: Colors.orange.shade50,
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MascotWidget(size: 120, animated: true),
                    const SizedBox(height: 20),
                    Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Great Job!",
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: Colors.orange.shade700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "After you practice a word,\nyour feedback will appear here! ⭐",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Build from AttemptRecord
    final String word = latest.word;
    final double accuracy = latest.accuracy;
    final double fluency = latest.fluency;
    final double completeness = latest.completeness;

    // Same scoring formula as before
    final double score =
        (accuracy * 0.6) + (fluency * 0.2) + (completeness * 0.2);

    Color scoreColor;
    String scoreEmoji;
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreEmoji = '🌟';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreEmoji = '👍';
    } else {
      scoreColor = Colors.red;
      scoreEmoji = '💪';
    }

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Tiger mascot celebrating
            const MascotWidget(size: 120, animated: true),
            const SizedBox(height: 20),

            // Word attempted - big and bold to be seen easily
            Card(
              elevation: 6,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.orange.shade300, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'You practiced:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Score card - child-friendly
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(scoreColor, Colors.white, 0.8)!,
                    Color.lerp(scoreColor, Colors.white, 0.6)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scoreColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(scoreEmoji, style: const TextStyle(fontSize: 50)),
                  const SizedBox(height: 12),
                  const Text(
                    "Your Score",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${score.toStringAsFixed(0)}/100",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color.lerp(scoreColor, Colors.black, 0.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    score >= 80
                        ? "Excellent! You're amazing! 🎉"
                        : score >= 60
                        ? "Good job! Keep practicing! 👏"
                        : "Keep trying! You'll get it! 💪",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color.lerp(scoreColor, Colors.black, 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed breakdown - simplified for kids
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "How You Did:",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildMetric("📝 Accuracy", accuracy, Colors.blue),
                    const SizedBox(height: 12),
                    _buildMetric("🎯 Fluency", fluency, Colors.purple),
                    const SizedBox(height: 12),
                    _buildMetric("✅ Completeness", completeness, Colors.green),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recognized text if available
            if (latest.recognizedText.isNotEmpty) ...[
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "We heard you say:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        latest.recognizedText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, double value, Color color) {
    // Convert Color to MaterialColor for proper shading
    final MaterialColor materialColor = _toMaterialColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: materialColor.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: materialColor.shade200, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${value.toStringAsFixed(0)}%",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: materialColor.shade700,
            ),
          ),
        ],
      ),
    );
  }

  MaterialColor _toMaterialColor(Color color) {
    if (color is MaterialColor) return color;

    final int colorValue = color.value;
    return MaterialColor(colorValue, {
      50: Color.lerp(color, Colors.white, 0.9)!,
      100: Color.lerp(color, Colors.white, 0.8)!,
      200: Color.lerp(color, Colors.white, 0.6)!,
      300: Color.lerp(color, Colors.white, 0.4)!,
      400: Color.lerp(color, Colors.white, 0.2)!,
      500: color,
      600: Color.lerp(color, Colors.black, 0.1)!,
      700: Color.lerp(color, Colors.black, 0.2)!,
      800: Color.lerp(color, Colors.black, 0.3)!,
      900: Color.lerp(color, Colors.black, 0.4)!,
    });
  }
}
