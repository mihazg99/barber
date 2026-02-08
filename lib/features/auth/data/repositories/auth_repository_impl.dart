import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/auth/domain/failures/auth_failure.dart';
import 'package:barber/features/auth/domain/repositories/auth_repository.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._authDataSource,
    this._userRepository,
    this._brandId, {
    void Function(UserEntity)? onUserLoaded,
  }) : _onUserLoaded = onUserLoaded;

  final AuthRemoteDataSource _authDataSource;
  final UserRepository _userRepository;
  final String _brandId;
  final void Function(UserEntity)? _onUserLoaded;

  @override
  String? get currentUserId => _authDataSource.auth.currentUser?.uid;

  @override
  Future<Either<Failure, String>> sendOtp(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return const Left(AuthInvalidPhoneFailure());
    if (trimmed.length < 10) return const Left(AuthInvalidPhoneFailure());

    try {
      final verificationId = await _authDataSource.sendOtp(trimmed);
      return Right(verificationId);
    } on FirebaseAuthException catch (e) {
      return Left(AuthVerificationFailedFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthVerificationFailedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return const Left(AuthInvalidOtpFailure());
    if (trimmed.length < 6) return const Left(AuthInvalidOtpFailure());

    try {
      final user = await _authDataSource.verifyOtp(
        verificationId: verificationId,
        code: trimmed,
      );

      final entity = UserEntity(
        userId: user.uid,
        fullName: '',
        phone: user.phoneNumber ?? '',
        fcmToken: '',
        brandId: _brandId,
        loyaltyPoints: 0,
        role: UserRole.user,
      );

      final existingResult = await _userRepository.getById(user.uid);
      final toSave = existingResult.fold(
        (_) => entity,
        (existing) =>
            existing != null
                ? existing.copyWith(
                  phone:
                      existing.phone.isNotEmpty
                          ? existing.phone
                          : (user.phoneNumber ?? entity.phone),
                )
                : entity,
      );

      _onUserLoaded?.call(toSave);
      final setResult = await _userRepository.set(toSave);
      // Always return user so profile step can show; if set failed, user can retry on submit.
      return setResult.fold((_) => Right(toSave), (_) => Right(toSave));
    } on FirebaseAuthException catch (e) {
      return Left(AuthSignInFailedFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthSignInFailedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await _authDataSource.signInWithGoogle();

      final displayName = user.displayName ?? '';
      final email = user.email ?? '';
      final phone = user.phoneNumber ?? '';

      final entity = UserEntity(
        userId: user.uid,
        fullName: displayName,
        phone: phone,
        fcmToken: '',
        brandId: _brandId,
        loyaltyPoints: 0,
        role: UserRole.user,
      );

      final existingResult = await _userRepository.getById(user.uid);
      final toSave = existingResult.fold(
        (_) => entity,
        (existing) =>
            existing != null
                ? existing.copyWith(
                  fullName:
                      existing.fullName.isNotEmpty
                          ? existing.fullName
                          : displayName,
                  phone: existing.phone.isNotEmpty ? existing.phone : phone,
                )
                : entity,
      );

      _onUserLoaded?.call(toSave);
      final setResult = await _userRepository.set(toSave);
      // Always return user so profile step can show; if set failed, user can retry on submit.
      return setResult.fold((_) => Right(toSave), (_) => Right(toSave));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign-in-cancelled') {
        return Left(AuthSignInCancelledFailure());
      }
      return Left(AuthSignInFailedFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthSignInFailedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    try {
      final user = await _authDataSource.signInWithApple();

      final displayName = user.displayName ?? '';
      final email = user.email ?? '';
      final phone = user.phoneNumber ?? '';

      final entity = UserEntity(
        userId: user.uid,
        fullName: displayName,
        phone: phone,
        fcmToken: '',
        brandId: _brandId,
        loyaltyPoints: 0,
        role: UserRole.user,
      );

      final existingResult = await _userRepository.getById(user.uid);
      final toSave = existingResult.fold(
        (_) => entity,
        (existing) =>
            existing != null
                ? existing.copyWith(
                  fullName:
                      existing.fullName.isNotEmpty
                          ? existing.fullName
                          : displayName,
                  phone: existing.phone.isNotEmpty ? existing.phone : phone,
                )
                : entity,
      );

      _onUserLoaded?.call(toSave);
      final setResult = await _userRepository.set(toSave);
      // Always return user so profile step can show; if set failed, user can retry on submit.
      return setResult.fold((_) => Right(toSave), (_) => Right(toSave));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign-in-cancelled') {
        return Left(AuthSignInCancelledFailure());
      }
      if (e.code == 'apple-sign-in-not-available') {
        return Left(
          AuthSignInFailedFailure(
            'Apple Sign-In is not available. Please ensure you have an Apple Developer Program membership and have configured Sign In with Apple.',
          ),
        );
      }
      return Left(AuthSignInFailedFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthSignInFailedFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAppleSignInAvailable() async {
    return await _authDataSource.isAppleSignInAvailable();
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Sign out failed: $e'));
    }
  }

  @override
  Stream<String?> get authStateChanges =>
      _authDataSource.authStateChanges.map((u) => u?.uid);
}
