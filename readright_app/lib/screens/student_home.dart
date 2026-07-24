// lib/screens/student_home.dart
//
// Main home screen for students with bottom navigation
// (Words, Practice, Feedback, Progress). Each tab is
// wired to the current student's ID so progress is
// tracked per student.

import 'package:flutter/material.dart';

import '../services/student_session_service.dart';
import '../models/student.dart';

import 'practice_screen.dart';
import 'feedback_screen.dart';
import 'progress_screen.dart';
import 'fill_blank_game_screen.dart';

class StudentHome extends StatefulWidget {
  final String studentId;

  const StudentHome({super.key, required this.studentId});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _selectedIndex = 0;
  Student? _student;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadStudent();

    // Build tab screens using the current student's ID.
    _screens = [
      PracticeScreen(studentId: widget.studentId),
      FillBlankGameScreen(studentId: widget.studentId),
      FeedbackScreen(studentId: widget.studentId),
      ProgressScreen(studentId: widget.studentId),
    ];
  }

  Future<void> _loadStudent() async {
    final s = await StudentSessionService.loadStudent();
    if (!mounted) return;
    setState(() {
      _student = s;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _student?.name ?? "Student";

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $name'),
        backgroundColor: const Color(0xFFFFCC80),
      ),
      body: _screens[_selectedIndex],
      backgroundColor: Colors.orange.shade50,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFFCC80),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.brown,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Practice'),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: 'Game'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
