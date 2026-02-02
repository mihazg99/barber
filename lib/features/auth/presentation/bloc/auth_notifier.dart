import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/failures/auth_failure.dart';
import 'package:barber/features/auth/domain/repositories/auth_repository.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';

class AuthNotifier extends BaseNotifier<AuthFlowData, AuthFailure> {
  AuthNotifier(this._authRepository, this._userRepository) {
    setData(const AuthFlowData(step: AuthStep.phoneInput));
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  /// Sends OTP to [phone]. On success, moves to OTP verification step.
  Future<void> sendOtp(String phone) async {
    final current = data ?? const AuthFlowData(step: AuthStep.phoneInput);
    setData(current.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepository.sendOtp(phone);
    result.fold(
      (failure) => setData(current.copyWith(isLoading: false, errorMessage: failure.message)),
      (verificationId) => setData(AuthFlowData(
        step: AuthStep.otpVerification,
        phone: phone.trim(),
        verificationId: verificationId,
      )),
    );
  }

  /// Verifies OTP. On success, Firebase Auth updates and router redirects.
  Future<void> verifyOtp(String code) async {
    final current = data;
    if (current == null || current.verificationId == null) {
      setData((current ?? const AuthFlowData(step: AuthStep.otpVerification))
          .copyWith(errorMessage: const AuthInvalidOtpFailure().message));
      return;
    }
    setData(current.copyWith(isLoading: true, errorMessage: null));
    final result = await _authRepository.verifyOtp(
      verificationId: current.verificationId!,
      code: code,
    );
    result.fold(
      (failure) => setData(current.copyWith(isLoading: false, errorMessage: failure.message)),
      (user) {
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

  /// Saves profile (full name) and completes flow. Router redirects when profile is complete.
  Future<void> submitProfile(UserEntity user, String fullName) async {
    final current = data;
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      setData((current ?? const AuthFlowData(step: AuthStep.profileInfo))
          .copyWith(errorMessage: 'Please enter your name'));
      return;
    }
    setData((current ?? const AuthFlowData(step: AuthStep.profileInfo))
        .copyWith(isLoading: true, errorMessage: null));
    final result = await _userRepository.set(user.copyWith(fullName: trimmed));
    result.fold(
      (failure) => setData((current ?? const AuthFlowData(step: AuthStep.profileInfo))
          .copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => setData((current ?? const AuthFlowData(step: AuthStep.profileInfo))
          .copyWith(isLoading: false, errorMessage: null)),
    );
  }

  /// Goes back to phone input step.
  void backToPhoneInput() {
    final current = data;
    if (current == null) return;
    setData(current.copyWith(
      step: AuthStep.phoneInput,
      verificationId: null,
      errorMessage: null,
    ));
  }

  /// Resets to initial phone input state.
  void reset() {
    setData(const AuthFlowData(step: AuthStep.phoneInput));
  }

  Future<void> signOut() async {
    final result = await _authRepository.signOut();
    result.fold(
      (failure) => setError(failure.message, failure),
      (_) => reset(),
    );
  }
}
