import 'package:flutter/material.dart';

import '../services/student_repository.dart';
import '../services/student_session_service.dart';
import '../models/student.dart';
import 'student_home.dart';

class StudentSelectionScreen extends StatefulWidget {
  const StudentSelectionScreen({super.key});

  @override
  State<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends State<StudentSelectionScreen> {
  List<Student> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    // TODO: replace these with real teacher/class values once wired up
    const teacherId = "teacher_fixed";
    const classId = "default_class";

    final repo = StudentRepository();
    final loaded = await repo.getStudents(
      teacherId: teacherId,
      classId: classId,
    );

    if (!mounted) return;
    setState(() {
      students = loaded;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Choose Your Name")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: students.isEmpty
            ? const Center(
                child: Text(
                  "No students found.\nAsk your teacher to add you!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
              )
            : GridView.builder(
                itemCount: students.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (_, index) {
                  final s = students[index];
                  final emoji = _emojiForAvatar(s.avatar);

                  return InkWell(
                    onTap: () async {
                      // -----------------------------------------------------
                      // NEW — PIN CHECK
                      // -----------------------------------------------------
                      if (s.pin.isNotEmpty) {
                        final ok = await _showPinDialog(context, s);
                        if (!ok) return; // wrong PIN → exit
                      }

                      // Save selected student
                      await StudentSessionService.saveStudent(s);

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentHome(studentId: s.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.indigo.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            s.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PIN DIALOG
  // --------------------------------------------------------------------------
  Future<bool> _showPinDialog(BuildContext context, Student s) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter PIN for ${s.name}"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(hintText: "Enter your PIN"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim() == s.pin.trim()) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect PIN, try again."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // --------------------------------------------------------------------------
  // Avatar → Emoji
  // --------------------------------------------------------------------------
  String _emojiForAvatar(String avatar) {
    switch (avatar) {
      case 'tiger':
        return '🐯';
      case 'fox':
        return '🦊';
      case 'bear':
        return '🐻';
      case 'panda':
        return '🐼';
      case 'bunny':
        return '🐰';
      case 'frog':
        return '🐸';
      case 'lion':
        return '🦁';
      case 'cat':
        return '🐱';
      case 'dog':
        return '🐶';
      default:
        return '🙂';
    }
  }
}
