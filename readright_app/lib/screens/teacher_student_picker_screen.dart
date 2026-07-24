import 'package:flutter/material.dart';
import '../services/student_repository.dart';
import '../models/student.dart';
import 'student_progress_screen.dart';

class TeacherStudentPickerScreen extends StatefulWidget {
  final String teacherId;
  final String classId;

  const TeacherStudentPickerScreen({
    super.key,
    required this.teacherId,
    required this.classId,
  });

  @override
  State<TeacherStudentPickerScreen> createState() =>
      _TeacherStudentPickerScreenState();
}

class _TeacherStudentPickerScreenState
    extends State<TeacherStudentPickerScreen> {
  bool loading = true;
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = StudentRepository();
    final result = await repo.getStudents(
      teacherId: widget.teacherId,
      classId: widget.classId,
    );

    setState(() {
      students = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Student")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: students.length,
        itemBuilder: (_, i) {
          final s = students[i];
          return Card(
            child: ListTile(
              title: Text(s.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentProgressScreen(studentId: s.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
