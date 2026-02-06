import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/failures/auth_failure.dart';
import 'package:barber/features/auth/domain/repositories/auth_repository.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';

class AuthNotifier extends BaseNotifier<AuthFlowData, AuthFailure> {
  AuthNotifier(
    this._authRepository,
    this._userRepository, {
    void Function(UserEntity?)? onSignInUser,
  })  : _onSignInUser = onSignInUser {
    setData(const AuthFlowData(step: AuthStep.landing));
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final void Function(UserEntity?)? _onSignInUser;

  /// Sends OTP to [phone]. On success, moves to OTP verification step.
  Future<void> sendOtp(String phone) async {
    final current = data ?? const AuthFlowData(step: AuthStep.phoneInput);
    setData(current.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepository.sendOtp(phone);
    result.fold(
      (failure) => setData(
        current.copyWith(isLoading: false, errorMessage: failure.message),
      ),
      (verificationId) => setData(
        AuthFlowData(
          step: AuthStep.otpVerification,
          phone: phone.trim(),
          verificationId: verificationId,
        ),
      ),
    );
  }

  /// Verifies OTP. On success, Firebase Auth updates and router redirects.
  Future<void> verifyOtp(String code) async {
    final current = data;
    if (current == null || current.verificationId == null) {
      setData(
        (current ?? const AuthFlowData(step: AuthStep.otpVerification))
            .copyWith(errorMessage: const AuthInvalidOtpFailure().message),
      );
      return;
    }
    setData(current.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepository.verifyOtp(
      verificationId: current.verificationId!,
      code: code,
    );
    result.fold(
      (failure) => setData(
        current.copyWith(isLoading: false, errorMessage: failure.message),
      ),
      (user) {
        _onSignInUser?.call(user);
        final needsProfile = user.fullName.trim().isEmpty;
        setData(
          current.copyWith(
            isLoading: false,
            step: needsProfile ? AuthStep.profileInfo : current.step,
            user: needsProfile ? user : current.user,
          ),
        );
      },
    );
  }

  /// Saves profile (full name and phone) and completes flow. Router redirects when profile is complete.
  Future<void> submitProfile(UserEntity user, String fullName, String phone) async {
    final current = data;
    final trimmedName = fullName.trim();
    final trimmedPhone = phone.trim();
    
    if (trimmedName.isEmpty) {
      setData(
        (current ?? const AuthFlowData(step: AuthStep.profileInfo)).copyWith(
          errorMessage: 'Please enter your name',
        ),
      );
      return;
    }
    
    if (trimmedPhone.isEmpty || trimmedPhone.length < 10) {
      setData(
        (current ?? const AuthFlowData(step: AuthStep.profileInfo)).copyWith(
          errorMessage: 'Please enter a valid phone number',
        ),
      );
      return;
    }
    
    setData(
      (current ?? const AuthFlowData(step: AuthStep.profileInfo)).copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await _userRepository.set(
      user.copyWith(
        fullName: trimmedName,
        phone: trimmedPhone,
      ),
    );
    result.fold(
      (failure) => setData(
        (current ?? const AuthFlowData(step: AuthStep.profileInfo)).copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => setData(
        (current ?? const AuthFlowData(step: AuthStep.profileInfo)).copyWith(
          isLoading: false,
          errorMessage: null,
        ),
      ),
    );
  }

  /// Navigates to phone input step.
  void navigateToPhoneInput() {
    final current = data ?? const AuthFlowData(step: AuthStep.landing);
    setData(
      current.copyWith(
        step: AuthStep.phoneInput,
        verificationId: null,
        errorMessage: null,
      ),
    );
  }

  /// Goes back to phone input step.
  void backToPhoneInput() {
    final current = data;
    if (current == null) return;
    setData(
      current.copyWith(
        step: AuthStep.phoneInput,
        verificationId: null,
        errorMessage: null,
      ),
    );
  }

  /// Signs in with Google. Always leads to profile completion to collect phone number.
  Future<void> signInWithGoogle({required bool requireSmsVerification}) async {
    final current = data ?? const AuthFlowData(step: AuthStep.landing);
    setData(current.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      (failure) {
        // Don't show error for cancelled sign-in
        if (failure is! AuthSignInCancelledFailure) {
          setData(
            current.copyWith(
              isLoading: false,
              errorMessage: failure.message,
            ),
          );
        } else {
          setData(current.copyWith(isLoading: false));
        }
      },
      (user) {
        _onSignInUser?.call(user);
        // Always go to profile step to collect phone number (unless both name and phone are present)
        final needsProfile = user.fullName.trim().isEmpty || user.phone.trim().isEmpty;
        
        if (needsProfile) {
          // Move to profile step
          setData(
            current.copyWith(
              isLoading: false,
              step: AuthStep.profileInfo,
              user: user,
            ),
          );
        } else {
          // User is complete, router will redirect
          setData(
            current.copyWith(
              isLoading: false,
              user: user,
            ),
          );
        }
      },
    );
  }

  /// Signs in with Apple. Always leads to profile completion to collect phone number.
  Future<void> signInWithApple({required bool requireSmsVerification}) async {
    final current = data ?? const AuthFlowData(step: AuthStep.landing);
    setData(current.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepository.signInWithApple();
    result.fold(
      (failure) {
        // Don't show error for cancelled sign-in
        if (failure is! AuthSignInCancelledFailure) {
          setData(
            current.copyWith(
              isLoading: false,
              errorMessage: failure.message,
            ),
          );
        } else {
          setData(current.copyWith(isLoading: false));
        }
      },
      (user) {
        _onSignInUser?.call(user);
        // Always go to profile step to collect phone number (unless both name and phone are present)
        final needsProfile = user.fullName.trim().isEmpty || user.phone.trim().isEmpty;
        
        if (needsProfile) {
          // Move to profile step
          setData(
            current.copyWith(
              isLoading: false,
              step: AuthStep.profileInfo,
              user: user,
            ),
          );
        } else {
          // User is complete, router will redirect
          setData(
            current.copyWith(
              isLoading: false,
              user: user,
            ),
          );
        }
      },
    );
  }

  /// Resets to initial landing state.
  void reset() {
    setData(const AuthFlowData(step: AuthStep.landing));
  }

  Future<void> signOut() async {
    _onSignInUser?.call(null);
    final result = await _authRepository.signOut();
    result.fold(
      (failure) => setError(failure.message, failure),
      (_) => reset(),
    );
  }
}
