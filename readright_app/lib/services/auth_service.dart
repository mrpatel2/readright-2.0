import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enums.dart';

// Handles Firebase Authentication and session persistence.
class AuthService extends ChangeNotifier {
  static const _kRoleKey = 'auth.role'; // key used in local storage
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserRole? _role;
  bool _loading = true;

  User? get user => _auth.currentUser;
  UserRole? get role => _role;
  bool get isLoggedIn => user != null;
  bool get isLoading => _loading;

  // Load saved session + role
  Future<void> init() async {
    print('🔄 AuthService.init starting...');
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kRoleKey);
    _role = UserRoleX.from(stored);

    // Firebase auto-restores login if user was previously authenticated
    await _auth.authStateChanges().first;

    _loading = false;
    notifyListeners();
    print('✅ AuthService.init done (role=$_role, loggedIn=$isLoggedIn)');
  }

  // --- SIGN UP ---
  Future<void> signup({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    print('🟣 Signing up user: $email ($role)');
    _loading = true;
    notifyListeners();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveRole(role);
      print('✅ Firebase signup successful');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase signup error: ${e.message}');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- LOGIN ---
  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    print('🟢 Logging in user: $email ($role)');
    _loading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _saveRole(role);
      print('✅ Firebase login successful');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase login error: ${e.message}');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    print('🚪 Logging out...');
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRoleKey);

    _role = null;
    notifyListeners();
  }

  // --- Helper: Save role locally ---
  Future<void> _saveRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRoleKey, role.key);
    _role = role;
    notifyListeners();
  }
}
