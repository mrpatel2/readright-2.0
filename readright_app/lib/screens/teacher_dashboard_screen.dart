import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teacher_student_picker_screen.dart';
import '../services/auth_service.dart';
import '../widgets/accessibility_button.dart';
import 'login_screen.dart';
import 'manage_word_list_screen.dart';
import 'student_progress_screen.dart';
import 'class_management_screen.dart';
import 'class_analytics_screen.dart';
import 'story_builder_screen.dart';

/// Professional dashboard for teachers
class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final teacherId = auth.user?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          const AccessibilityButton(isStudentMode: false),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----- HEADER CARD -----
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      // Use theme colors so high-contrast and color-blind modes affect header
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          // prefer primaryContainer if available for a nice two-tone effect
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ReadRight',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome back! Manage your students and word lists.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ----- QUICK ACTIONS TITLE -----
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // ======================================================
                //  ⭐ NEW — MANAGE CLASS ACTION CARD
                // ======================================================
                _buildActionCard(
                  context: context,
                  icon: Icons.group_add,
                  title: 'Manage Class',
                  description: 'Add or import students in your classroom',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassManagementScreen(
                          teacherId: teacherId,
                          classId: "default_class",
                          className: "My Class",
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ----- STUDENT PROGRESS -----
                _buildActionCard(
                  context: context,
                  icon: Icons.people,
                  title: 'Student Progress',
                  description: 'View and track student performance',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherStudentPickerScreen(
                          teacherId: teacherId,
                          classId: "default_class",
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ----- MANAGE WORD LISTS -----
                _buildActionCard(
                  context: context,
                  icon: Icons.list_alt,
                  title: 'Manage Word Lists',
                  description: 'Create and edit word lists for students',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageWordListScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ----- ANALYTICS -----
                _buildActionCard(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  description: 'View detailed reports and insights',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassAnalyticsScreen(
                          teacherId: teacherId,
                          classId: 'default_class',
                          className: 'My Class',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ----- AI STORY BUILDER -----
                _buildActionCard(
                  context: context,
                  icon: Icons.auto_stories,
                  title: 'AI Story Builder',
                  description:
                      'Generate a leveled, interest-driven Dolch story for a student',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryBuilderScreen(
                          teacherId: teacherId,
                          classId: "default_class",
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ----- ABOUT CARD -----
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About ReadRight',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ReadRight helps students practice reading words aloud with real-time feedback and pronunciation assessment.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================================================
  //  CARD BUILDER WIDGET
  // ======================================================
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final MaterialColor materialColor = _toMaterialColor(color);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: materialColor.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: materialColor.shade700, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  //  COLOR CONVERTER
  // ======================================================
  MaterialColor _toMaterialColor(Color color) {
    if (color is MaterialColor) return color;

    final int value = color.value;
    return MaterialColor(value, {
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
