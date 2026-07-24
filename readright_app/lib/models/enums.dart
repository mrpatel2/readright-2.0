// User roles in the app: Student or Teacher
enum UserRole { student, teacher }

// Helper methods for saving and loading roles as strings
extension UserRoleX on UserRole {
  // Returns the string form of the role
  String get key => name;
  // Converts a string back to a UserRole
  static UserRole? from(String? s) {
    if (s == null) return null;
    return UserRole.values.firstWhere(
      (e) => e.name == s,
      orElse: () => UserRole.student,
    );
  }
}
