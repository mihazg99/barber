/// User role for access control. Stored in `users` collection.
///
/// - [UserRole.user]: Regular app user (client). Sees main app (home, booking, loyalty).
/// - [UserRole.barber]: Barber/employee. Navigates to dashboard.
/// - [UserRole.superadmin]: Superadmin. Navigates to dashboard. Can manage brands, users, etc.
///
/// Role assignment: Only `user` can be set by clients. `barber` and `superadmin` must be
/// assigned via Firebase Admin SDK (Cloud Functions or admin tool) for security.
enum UserRole {
  user('user'),
  barber('barber'),
  superadmin('superadmin');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'barber':
        return UserRole.barber;
      case 'superadmin':
        return UserRole.superadmin;
      default:
        return UserRole.user;
    }
  }

  /// True if this role should navigate to dashboard instead of main app.
  bool get isStaff => this == UserRole.barber || this == UserRole.superadmin;
}
