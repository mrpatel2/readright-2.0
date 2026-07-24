import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

// Models & Services
import 'models/enums.dart';
import 'services/auth_service.dart';
import 'services/accessibility_service.dart';
import 'services/student_session_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/student_home.dart';
import 'screens/student_selection_screen.dart';
import 'screens/teacher_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = AuthService();
  await auth.init();

  final accessibility = AccessibilityService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AccessibilityService>.value(
          value: accessibility,
        ),
      ],
      child: const ReadRightApp(),
    ),
  );
}

class ReadRightApp extends StatelessWidget {
  const ReadRightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final accessibility = context.watch<AccessibilityService>();

    // --------------------------------------------------
    // SHOW SPLASH WHILE AUTH & SESSION LOAD
    // --------------------------------------------------
    if (auth.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.orange.shade50,
          body: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
      );
    }

    // --------------------------------------------------
    // DETERMINE WHICH SCREEN TO SHOW
    // --------------------------------------------------
    Widget home;

    if (!auth.isLoggedIn) {
      home = const LoginScreen();
    } else if (auth.role == UserRole.teacher) {
      home = const TeacherDashboardScreen();
    } else {
      // STUDENT ROLE LOGGED IN
      // Try restoring last selected student
      return FutureBuilder(
        future: StudentSessionService.loadStudent(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final saved = snapshot.data;

          if (saved == null) {
            // Student logged in — but hasn't selected their name yet
            home = const StudentSelectionScreen();
          } else {
            // Student has a saved profile
            home = StudentHome(studentId: saved.id);
          }

          // Continue building app with theming
          return _buildThemedApp(context, accessibility, auth, home);
        },
      );
    }

    return _buildThemedApp(context, accessibility, auth, home);
  }

  // --------------------------------------------------
  // THEMING WRAPPER
  // --------------------------------------------------
  Widget _buildThemedApp(
    BuildContext context,
    AccessibilityService accessibility,
    AuthService auth,
    Widget home,
  ) {
    // -------------------------
    // STUDENT THEME
    // -------------------------
    final studentTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        primary: Colors.orange.shade600,
        secondary: Colors.amber.shade500,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.quicksandTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: const TextStyle(fontSize: 20),
            bodyMedium: const TextStyle(fontSize: 18),
            labelLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
      scaffoldBackgroundColor: Colors.orange.shade50,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // -------------------------
    // TEACHER THEME (base)
    // -------------------------
    final teacherThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        primary: Colors.indigo.shade700,
        secondary: Colors.blue.shade600,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    // -------------------------
    // APPLY ACCESSIBILITY ADJUSTMENTS (UI only)
    // -------------------------
    ThemeData baseTheme = auth.isLoggedIn && auth.role == UserRole.student
        ? studentTheme
        : teacherThemeBase;

    ThemeData appliedTheme = baseTheme;

    // Color-blind mode: shift to a palette that avoids problematic red/green
    if (accessibility.colorBlind) {
      final ColorScheme cbScheme = baseTheme.colorScheme.copyWith(
        primary: Colors.blue.shade800,
        secondary: Colors.amber.shade700,
      );

      appliedTheme = baseTheme.copyWith(
        colorScheme: cbScheme,
        appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
        ),
      );
    }

    // High-contrast option removed — no additional theme changes here.

    return MaterialApp(
      title: "ReadRight",
      debugShowCheckedModeBanner: false,
      theme: appliedTheme,
      home: home,
    );
  }
}
