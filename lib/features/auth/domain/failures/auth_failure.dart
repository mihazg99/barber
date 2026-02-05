import 'package:barber/core/errors/failure.dart';

/// Auth-specific failures.
sealed class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class AuthInvalidPhoneFailure extends AuthFailure {
  const AuthInvalidPhoneFailure() : super('Please enter a valid phone number');
}

class AuthInvalidOtpFailure extends AuthFailure {
  const AuthInvalidOtpFailure()
    : super('Please enter a valid verification code');
}

class AuthVerificationFailedFailure extends AuthFailure {
  const AuthVerificationFailedFailure([super.message = 'Verification failed']);
}

class AuthSignInFailedFailure extends AuthFailure {
  const AuthSignInFailedFailure([super.message = 'Sign in failed']);
}

class AuthSignInCancelledFailure extends AuthFailure {
  const AuthSignInCancelledFailure()
      : super('Sign in was cancelled');
}
