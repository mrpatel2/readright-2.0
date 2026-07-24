import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/local_progress_service.dart';
import '../models/attempt_record.dart';
import '../widgets/mascot_widget.dart';

class ProgressScreen extends StatefulWidget {
  final String studentId;
  const ProgressScreen({super.key, required this.studentId});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late LocalProgressService _progressService;
  List<AttemptRecord> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _progressService = LocalProgressService(studentId: widget.studentId);
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() => _isLoading = true);
    final attempts = await _progressService.getAttempts();
    setState(() {
      _attempts = attempts;
      _isLoading = false;
    });

    debugPrint('\n--- USER ATTEMPT LOG ---');
    if (attempts.isEmpty) {
      debugPrint('No attempts recorded yet.');
    } else {
      for (final attempt in attempts) {
        debugPrint(
          '[${attempt.timestamp.toLocal()}] - '
          'Word: "${attempt.word}" - '
          'Correct: ${attempt.correct ? 'YES' : 'NO'}',
        );
      }
    }
    debugPrint('--- END OF LOG ---\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    if (_attempts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotWidget(size: 120, animated: true),
              const SizedBox(height: 24),
              Icon(Icons.bar_chart, size: 60, color: Colors.orange.shade600),
              const SizedBox(height: 16),
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Practice some words to see\nyour progress here! 📊',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate stats
    final correctCount = _attempts.where((a) => a.correct).length;
    final totalCount = _attempts.length;
    final percentage = totalCount > 0
        ? (correctCount / totalCount * 100).round()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Stats card with tiger mascot
          Card(
            elevation: 6,
            color: Colors.orange.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.orange.shade300, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const MascotWidget(size: 80, animated: true),
                  const SizedBox(height: 12),
                  Text(
                    'Your Stats',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.orange.shade900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '✅ Correct',
                        correctCount.toString(),
                        Colors.green,
                      ),
                      _buildStatItem(
                        '📝 Total',
                        totalCount.toString(),
                        Colors.blue,
                      ),
                      _buildStatItem('⭐ Score', '$percentage%', Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recent attempts header
          Text(
            'Recent Words',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.orange.shade800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),

          // List of attempts - child-friendly
          ...List.generate(_attempts.length, (index) {
            final attempt =
                _attempts[_attempts.length - 1 - index]; // Reverse order
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: attempt.correct
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    attempt.correct ? Icons.check_circle : Icons.cancel,
                    color: attempt.correct
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 24,
                  ),
                ),
                title: Text(
                  attempt.word,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  attempt.listName,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDate(attempt.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    // Convert Color to MaterialColor for shading
    final int colorValue = color.value;
    final MaterialColor materialColor = color is MaterialColor
        ? color
        : MaterialColor(colorValue, {
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: materialColor.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: materialColor.shade300, width: 2),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: materialColor.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
