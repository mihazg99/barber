import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/primary_button.dart';

class AuthLanding extends HookConsumerWidget {
  const AuthLanding({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.isLoading = false,
    this.errorMessage,
    this.showAppleSignIn = false,
  });

  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final bool isLoading;
  final String? errorMessage;
  final bool showAppleSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.welcome ?? 'Welcome',
          style: context.appTextStyles.h1.copyWith(
            color: context.appColors.primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        Gap(context.appSizes.paddingLarge),
        Text(
          context.l10n.signInToContinue ?? 'Sign in to continue',
          style: context.appTextStyles.body.copyWith(
            color: context.appColors.captionTextColor,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        Gap(context.appSizes.paddingXxl * 2),
        PrimaryButton.big(
          onPressed: isLoading ? null : onGoogleSignIn,
          loading: isLoading,
          icon: Icon(
            Icons.g_mobiledata,
            color: context.appColors.primaryWhiteColor,
            size: 24,
          ),
          child: Text(
            context.l10n.continueWithGoogle,
          ),
        ),
        if (showAppleSignIn) ...[
          Gap(context.appSizes.paddingMedium),
          PrimaryButton.big(
            onPressed: isLoading ? null : onAppleSignIn,
            loading: isLoading,
            color: Colors.black,
            textColor: Colors.white,
            icon: Icon(
              Icons.apple,
              color: Colors.white,
              size: 24,
            ),
            child: Text(
              context.l10n.continueWithApple,
            ),
          ),
        ],
        if (errorMessage != null) ...[
          Gap(context.appSizes.paddingMedium),
          _ErrorText(message: errorMessage!),
        ],
      ],
    );
  }
}

/// Error message widget matching home page style
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: context.appColors.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        border: Border.all(
          color: context.appColors.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: context.appColors.errorColor,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
