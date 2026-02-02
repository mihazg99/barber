import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth wrapper for phone OTP operations.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._auth);

  final FirebaseAuth _auth;

  FirebaseAuth get auth => _auth;

  /// Sends OTP to [phone]. Returns verification ID when SMS is sent.
  Future<String> sendOtp(String phone) async {
    final completer = Completer<String>();
    final normalizedPhone =
        phone.trim().startsWith('+') ? phone.trim() : '+$phone';

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      verificationCompleted: (_) {
        // Auto-verification (e.g. instant verify on same device)
        if (!completer.isCompleted) {
          completer.completeError(
            FirebaseAuthException(
              code: 'verification-completed',
              message: 'Use verifyOtp for manual verification',
            ),
          );
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {
        // Do not complete - wait for codeSent
      },
    );

    return completer.future;
  }

  /// Signs in with OTP credential.
  Future<User> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code.trim(),
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null)
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Sign in produced no user',
      );
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges().map((u) => u);
}
