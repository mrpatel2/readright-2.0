import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../widgets/mascot_widget.dart';

class ClassAnalyticsScreen extends StatefulWidget {
  final String teacherId;
  final String classId;
  final String className;

  const ClassAnalyticsScreen({
    super.key,
    required this.teacherId,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassAnalyticsScreen> createState() => _ClassAnalyticsScreenState();
}

class _ClassAnalyticsScreenState extends State<ClassAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  late Future<ClassAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _analyticsService.calculateClassAnalytics(
      teacherId: widget.teacherId,
      classId: widget.classId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.className} Analytics')),
      body: FutureBuilder<ClassAnalytics>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load analytics.'));
          }

          final analytics = snapshot.data!;

          if (analytics.problemWords.isEmpty &&
              analytics.averageAccuracy == 0) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MascotWidget(size: 100),
                  SizedBox(height: 16),
                  Text(
                    'No student data yet!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Practice some words to see analytics here.'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Performance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                Text(
                  'Top 10 Problem Words',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (analytics.problemWords.isEmpty)
                  const Text(
                    'No incorrect words have been recorded yet. Great job!',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: analytics.problemWords.length,
                    itemBuilder: (context, index) {
                      final problem = analytics.problemWords[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(
                            problem.word,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text('${problem.incorrectCount} misses'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
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
