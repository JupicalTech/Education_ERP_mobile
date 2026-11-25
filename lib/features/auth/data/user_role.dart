enum UserRole {
  superAdmin('super_admin', 'Super Admin', '/super-admin'),
  principal('principal', 'Principal', '/principal'),
  feeClerk('fee_clerk', 'Fee Clerk', '/fee-clerk'),
  teacher('teacher', 'Teacher', '/teacher'),
  student('student', 'Student', '/student'),
  parent('parent', 'Parent', '/parent');

  const UserRole(this.dbValue, this.label, this.homeRoute);

  /// Exact value stored in the PostgreSQL `user_role` enum.
  final String dbValue;

  /// Human-readable label for UI display.
  final String label;

  /// Default home route for this role.
  final String homeRoute;

  String toDb() => dbValue;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.dbValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown user_role value',
      ),
    );
  }
}
