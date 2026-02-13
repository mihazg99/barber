import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
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

class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);

    // From app config to avoid Firestore reads on auth screen (unauthenticated).
    final requireSmsVerification =
        ref
            .watch(flavorConfigProvider)
            .values
            .brandConfig
            .requireSmsVerification;

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
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.appSizes.paddingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _AuthCard(
                child: _AuthStepContent(
                  data: data,
                  notifier: notifier,
                  requireSmsVerification: requireSmsVerification,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean card container matching home page style
class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingXl),
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        border: Border.all(
          color: context.appColors.borderColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.valueOrNull;

    // Loading if auth finished but we are waiting for user profile data/check
    final isAuthLoading = isAuthenticated && currentUserAsync.isLoading;

    // Profile step: show when (a) we're in profile step with user (right after OTP, before auth stream updates)
    // or (b) authenticated but profile incomplete (and loaded). Use data.user first so we don't flash loading.
    final showProfile =
        (data.isProfileInfo && data.user != null) ||
        (isAuthenticated && !isProfileComplete && !isAuthLoading);

    if (showProfile) {
      final user = data.user ?? currentUser;
      if (user == null) {
        // Should not happen if !isAuthLoading logic works and user is loaded,
        // but as safety fallback we show loading.
        return const _AuthLoading();
      }
      return AuthProfileInput(
        user: user,
        onSubmit: (fullName, phone) async {
          await notifier.submitProfile(user, fullName, phone);

          if (!context.mounted) return;

          // Check for errors before proceeding
          final state = ref.read(authNotifierProvider);
          if (state is BaseError ||
              (state is BaseData<AuthFlowData> &&
                  state.data.errorMessage != null)) {
            return;
          }

          // Update cache immediately to prevent flash of incomplete profile state during reload
          ref.read(lastSignedInUserProvider.notifier).state = user.copyWith(
            fullName: fullName,
            phone: phone,
          );
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
          return await ref
              .watch(authRepositoryProvider)
              .isAppleSignInAvailable();
        }),
      );
      final isAppleSignInAvailable =
          appleSignInAvailableAsync.valueOrNull ?? false;

      return AuthLanding(
        onGoogleSignIn:
            () => notifier.signInWithGoogle(
              requireSmsVerification: requireSmsVerification,
            ),
        onAppleSignIn:
            () => notifier.signInWithApple(
              requireSmsVerification: requireSmsVerification,
            ),
        // Show loading if notifier is loading OR if we are waiting for profile check
        isLoading: data.isLoading || isAuthLoading,
        errorMessage: data.errorMessage,
        showAppleSignIn: isAppleSignInAvailable,
      );
    }

    if (data.isOtpVerification) {
      return AuthOtpInput(
        phone: data.phone ?? '',
        onVerify: notifier.verifyOtp,
        onBack: notifier.backToPhoneInput,
        isLoading: data.isLoading || isAuthLoading,
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
