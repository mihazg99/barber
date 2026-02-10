import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth wrapper for phone OTP and social login operations.
class AuthRemoteDataSource {
  AuthRemoteDataSource(
    this._auth,
    this._googleSignIn,
  );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

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

  /// Signs in with Google.
  Future<User> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Sign in produced no user',
        );
      }
      return user;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign in was cancelled',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Sign in produced no user',
      );
    }
    return user;
  }

  /// Signs in with Apple. Throws [FirebaseAuthException] if Apple Sign-In is not available.
  Future<User> signInWithApple() async {
    // Check if Apple Sign-In is available
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-not-available',
        message:
            'Apple Sign-In is not available. Please ensure you have an Apple Developer Program membership and have configured Sign In with Apple.',
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Sign in produced no user',
      );
    }
    return user;
  }

  /// Checks if Apple Sign-In is available on this device.
  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges().map((u) => u);
}
