import 'package:barber/core/errors/failure.dart';

/// Failure for Firestore / Firebase operations.
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}
