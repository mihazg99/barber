import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Returns the currently signed-in user ID, or null.
  String? get currentUserId;

  /// Sends OTP to [phone]. Phone must include country code (e.g. +1234567890).
  /// Returns [Right(verificationId)] on success, [Left] on failure.
  Future<Either<Failure, String>> sendOtp(String phone);

  /// Verifies OTP and signs in. Returns [Right(UserEntity)] on success.
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String code,
  });

  /// Signs in with Google. Returns [Right(UserEntity)] on success.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Signs in with Apple. Returns [Right(UserEntity)] on success.
  Future<Either<Failure, UserEntity>> signInWithApple();

  /// Checks if Apple Sign-In is available on this device.
  Future<bool> isAppleSignInAvailable();

  /// Signs out the current user.
  Future<Either<Failure, void>> signOut();

  /// Stream of auth state changes (user ID or null).
  Stream<String?> get authStateChanges;
}
