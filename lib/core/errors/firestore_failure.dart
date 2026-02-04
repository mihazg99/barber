import 'package:barber/core/errors/failure.dart';

/// Failure for Firestore / Firebase operations.
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, {this.code});

  /// Optional code for UI to map to localized messages (e.g. 'user-has-active-appointment').
  final String? code;
}
