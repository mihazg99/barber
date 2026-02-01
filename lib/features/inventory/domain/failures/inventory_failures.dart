import 'package:inventory/core/errors/failure.dart';

/// Database failure for inventory operations
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

/// Not found failure for inventory operations
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Validation failure for inventory operations
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
} 