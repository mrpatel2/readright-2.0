import '../models/student.dart';
import '../models/attempt_record.dart';
import '../services/word_list_service.dart';
import 'student_repository.dart';
import 'local_progress_service.dart';

// A data class to hold all calculated analytics for a class.
class ClassAnalytics {
  final double averageAccuracy;
  final double averageFluency;
  final double averageCompleteness;
  final List<ProblemWord> problemWords;

  ClassAnalytics({
    required this.averageAccuracy,
    required this.averageFluency,
    required this.averageCompleteness,
    required this.problemWords,
  });
}

class StudentAnalytics {
  final double averageAccuracy;
  final double averageFluency;
  final double averageCompleteness;
  final int masteredWords;
  final int totalWords;

  StudentAnalytics({
    required this.averageAccuracy,
    required this.averageFluency,
    required this.averageCompleteness,
    required this.masteredWords,
    required this.totalWords,
  });
}

// A data class to hold information about a problem word.
class ProblemWord {
  final String word;
  final int incorrectCount;

  ProblemWord({required this.word, required this.incorrectCount});
}

class AnalyticsService {
  final StudentRepository _studentRepo = StudentRepository();

  Future<ClassAnalytics> calculateClassAnalytics({
    required String teacherId,
    required String classId,
  }) async {
    final List<Student> students = await _studentRepo.getStudents(
      teacherId: teacherId,
      classId: classId,
    );

    final List<AttemptRecord> allAttempts = [];
    for (final student in students) {
      final progressService = LocalProgressService(studentId: student.id);
      final studentAttempts = await progressService.getAllAttempts();
      allAttempts.addAll(studentAttempts);
    }

    if (allAttempts.isEmpty) {
      return ClassAnalytics(
        averageAccuracy: 0,
        averageFluency: 0,
        averageCompleteness: 0,
        problemWords: [],
      );
    }

    // Calculate average scores
    final double totalAccuracy = allAttempts
        .map((a) => a.accuracy)
        .reduce((a, b) => a + b);
    final double totalFluency = allAttempts
        .map((a) => a.fluency)
        .reduce((a, b) => a + b);
    final double totalCompleteness = allAttempts
        .map((a) => a.completeness)
        .reduce((a, b) => a + b);

    // Identify problem words
    final Map<String, int> incorrectCounts = {};
    final incorrectAttempts = allAttempts.where((a) => !a.correct);

    for (final attempt in incorrectAttempts) {
      incorrectCounts[attempt.word] = (incorrectCounts[attempt.word] ?? 0) + 1;
    }

    final List<ProblemWord> problemWords = incorrectCounts.entries.map((entry) {
      return ProblemWord(word: entry.key, incorrectCount: entry.value);
    }).toList();

    // Sort by count, descending
    problemWords.sort((a, b) => b.incorrectCount.compareTo(a.incorrectCount));

    return ClassAnalytics(
      averageAccuracy: totalAccuracy / allAttempts.length,
      averageFluency: totalFluency / allAttempts.length,
      averageCompleteness: totalCompleteness / allAttempts.length,
      problemWords: problemWords.take(10).toList(), // Top 10
    );
  }

  Future<StudentAnalytics> calculateStudentAnalytics(String studentId) async {
    final progressService = LocalProgressService(studentId: studentId);
    final wordListService = WordListService(progressService);
    final attempts = await progressService.getAllAttempts();
    final currentList = await wordListService.loadCurrentList();

    if (attempts.isEmpty) {
      return StudentAnalytics(
        averageAccuracy: 0,
        averageFluency: 0,
        averageCompleteness: 0,
        masteredWords: 0,
        totalWords: 0,
      );
    }

    final double totalAccuracy = attempts
        .map((a) => a.accuracy)
        .reduce((a, b) => a + b);
    final double totalFluency = attempts
        .map((a) => a.fluency)
        .reduce((a, b) => a + b);
    final double totalCompleteness = attempts
        .map((a) => a.completeness)
        .reduce((a, b) => a + b);

    final masteredCount = currentList.where((w) => w.mastered).length;

    return StudentAnalytics(
      averageAccuracy: totalAccuracy / attempts.length,
      averageFluency: totalFluency / attempts.length,
      averageCompleteness: totalCompleteness / attempts.length,
      masteredWords: masteredCount,
      totalWords: currentList.length,
    );
  }
}
