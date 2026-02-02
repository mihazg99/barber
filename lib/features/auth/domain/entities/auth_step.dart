import 'package:equatable/equatable.dart';

import 'package:barber/features/auth/domain/entities/user_entity.dart';

/// Step in the OTP auth flow.
enum AuthStep {
  phoneInput,
  otpVerification,
  profileInfo,
}

/// Data for the auth flow (phone input → OTP verify → optional profile).
class AuthFlowData extends Equatable {
  const AuthFlowData({
    required this.step,
    this.phone,
    this.verificationId,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  final AuthStep step;
  final String? phone;
  final String? verificationId;
  final UserEntity? user;
  final String? errorMessage;
  final bool isLoading;

  bool get isPhoneInput => step == AuthStep.phoneInput;
  bool get isOtpVerification => step == AuthStep.otpVerification;
  bool get isProfileInfo => step == AuthStep.profileInfo;

  AuthFlowData copyWith({
    AuthStep? step,
    String? phone,
    String? verificationId,
    UserEntity? user,
    String? errorMessage,
    bool? isLoading,
  }) =>
      AuthFlowData(
        step: step ?? this.step,
        phone: phone ?? this.phone,
        verificationId: verificationId ?? this.verificationId,
        user: user ?? this.user,
        errorMessage: errorMessage,
        isLoading: isLoading ?? this.isLoading,
      );

  AuthFlowData clearError() => copyWith(errorMessage: null);

  @override
  List<Object?> get props => [step, phone, verificationId, user, errorMessage, isLoading];
}
