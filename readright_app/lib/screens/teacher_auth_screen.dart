import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../models/enums.dart';
import 'teacher_dashboard_screen.dart';
import 'login_screen.dart';

class TeacherAuthScreen extends StatefulWidget {
  final bool isSignup;
  const TeacherAuthScreen({super.key, this.isSignup = false});

  @override
  State<TeacherAuthScreen> createState() => _TeacherAuthScreenState();
}

class _TeacherAuthScreenState extends State<TeacherAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSignup ? "Create Teacher Account" : "Teacher Login",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.person, size: 100, color: Colors.indigo.shade700),

            const SizedBox(height: 32),

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);

                        try {
                          if (widget.isSignup) {
                            await auth.signup(
                              email: _email.text.trim(),
                              password: _password.text.trim(),
                              role: UserRole.teacher,
                            );
                          } else {
                            await auth.login(
                              email: _email.text.trim(),
                              password: _password.text.trim(),
                              role: UserRole.teacher,
                            );
                          }

                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeacherDashboardScreen(),
                            ),
                            (_) => false,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: Text(
                  widget.isSignup ? "Create Account" : "Login",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!widget.isSignup)
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherAuthScreen(isSignup: true),
                    ),
                  );
                },
                child: const Text("Create a teacher account"),
              ),
          ],
        ),
      ),
    );
  }
}
