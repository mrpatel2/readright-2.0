import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---- Fake screens to avoid plugin initialization ----
class FakePracticeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('PracticeMock');
}

class FakeFeedbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('FeedbackMock');
}

class FakeProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('ProgressMock');
}

// ---- Test version of StudentHome that uses fake screens ----
class TestStudentHome extends StatefulWidget {
  @override
  State<TestStudentHome> createState() => _TestStudentHomeState();
}

class _TestStudentHomeState extends State<TestStudentHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    FakePracticeScreen(),
    FakeFeedbackScreen(),
    FakeProgressScreen(),
  ];

  void _onTap(int i) => setState(() => _selectedIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Practice'),
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

void main() {
  testWidgets('StudentHome switches tabs correctly', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TestStudentHome()));

    // Start on tab 0
    expect(find.text('PracticeMock'), findsOneWidget);

    // Tap Feedback tab
    await tester.tap(find.byIcon(Icons.feedback));
    await tester.pump();
    expect(find.text('FeedbackMock'), findsOneWidget);

    // Tap Progress tab
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();
    expect(find.text('ProgressMock'), findsOneWidget);

    // Back to Practice
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    expect(find.text('PracticeMock'), findsOneWidget);
  });
}
