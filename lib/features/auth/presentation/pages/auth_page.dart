import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart';
import 'package:barber/core/router/app_router.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/auth/presentation/bloc/auth_notifier.dart';
import 'package:barber/features/auth/presentation/widgets/auth_landing.dart';
import 'package:barber/features/auth/presentation/widgets/auth_otp_input.dart';
import 'package:barber/features/auth/presentation/widgets/auth_phone_input.dart';
import 'package:barber/features/auth/presentation/widgets/auth_profile_input.dart';
import 'package:barber/features/brand/di.dart';

class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);

    // Get brand to check if SMS verification is required
    final configBrandId =
        ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
    final brandId =
        configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
    final brandAsync = ref.watch(
      FutureProvider.autoDispose((ref) async {
        final result = await ref.watch(brandRepositoryProvider).getById(brandId);
        return result.fold((_) => null, (brand) => brand);
      }),
    );
    final requireSmsVerification =
        brandAsync.valueOrNull?.requireSmsVerification ?? false;

    final data = switch (authState) {
      BaseData(:final data) => data,
      BaseError(:final message) => AuthFlowData(
        step: AuthStep.landing,
        errorMessage: message,
      ),
      _ => const AuthFlowData(step: AuthStep.landing),
    };

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Gap(context.appSizes.paddingXxl),
              _AuthStepContent(
                data: data,
                notifier: notifier,
                requireSmsVerification: requireSmsVerification,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthStepContent extends ConsumerWidget {
  const _AuthStepContent({
    required this.data,
    required this.notifier,
    required this.requireSmsVerification,
  });

  final AuthFlowData data;
  final AuthNotifier notifier;
  final bool requireSmsVerification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated =
        ref.watch(isAuthenticatedProvider).valueOrNull ?? false;
    final isProfileComplete = ref.watch(isProfileCompleteProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    // Profile step: show when (a) we're in profile step with user (right after OTP, before auth stream updates)
    // or (b) authenticated but profile incomplete. Use data.user first so we don't flash loading.
    final showProfile =
        (data.isProfileInfo && data.user != null) ||
        (isAuthenticated && !isProfileComplete);
    if (showProfile) {
      final user = data.user ?? currentUser;
      if (user == null) {
        return const _AuthLoading();
      }
      return AuthProfileInput(
        user: user,
        onSubmit: (fullName, phone) async {
          await notifier.submitProfile(user, fullName, phone);
          ref.invalidate(currentUserProvider);
          await ref.read(currentUserProvider.future);
          ref.read(routerRefreshNotifierProvider).notify();
        },
        isLoading: data.isLoading,
        errorMessage: data.errorMessage,
      );
    }

    if (data.isLanding) {
      // Check if Apple Sign-In is available (only on iOS and if configured)
      final appleSignInAvailableAsync = ref.watch(
        FutureProvider.autoDispose<bool>((ref) async {
          return await ref.watch(authRepositoryProvider).isAppleSignInAvailable();
        }),
      );
      final isAppleSignInAvailable =
          appleSignInAvailableAsync.valueOrNull ?? false;

      return AuthLanding(
        onGoogleSignIn: () => notifier.signInWithGoogle(
          requireSmsVerification: requireSmsVerification,
        ),
        onAppleSignIn: () => notifier.signInWithApple(
          requireSmsVerification: requireSmsVerification,
        ),
        isLoading: data.isLoading,
        errorMessage: data.errorMessage,
        showAppleSignIn: isAppleSignInAvailable,
      );
    }

    if (data.isOtpVerification) {
      return AuthOtpInput(
        phone: data.phone ?? '',
        onVerify: notifier.verifyOtp,
        onBack: notifier.backToPhoneInput,
        isLoading: data.isLoading,
        errorMessage: data.errorMessage,
      );
    }

    return AuthPhoneInput(
      onSendOtp: notifier.sendOtp,
      isLoading: data.isLoading,
      errorMessage: data.errorMessage,
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingXxl),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            context.appColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
