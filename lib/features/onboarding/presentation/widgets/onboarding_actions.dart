import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/glass_button.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_data.dart';

class OnboardingActions extends StatelessWidget {
  const OnboardingActions({
    super.key,
    required this.data,
    required this.onSkip,
    required this.onNext,
    required this.onGetStarted,
    this.isCompleting = false,
  });

  final OnboardingData data;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;
  final bool isCompleting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!data.isLastPage)
            TextButton(
              onPressed: isCompleting ? null : onSkip,
              child: Text(
                context.l10n.skip,
                style: context.appTextStyles.body.copyWith(
                  color: context.appColors.captionTextColor,
                ),
              ),
            )
          else
            Gap(context.appSizes.paddingXxl),
          if (data.isLastPage)
            SizedBox(
              width: double.infinity,
              child: GlassPrimaryButton(
                label: context.l10n.getStarted,
                onTap: isCompleting ? null : onGetStarted,
                loading: isCompleting,
                enabled: !isCompleting,
                accentColor: context.appColors.primaryColor,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: GlassPrimaryButton(
                label: context.l10n.next,
                onTap: isCompleting ? null : onNext,
                enabled: !isCompleting,
                accentColor: context.appColors.primaryColor,
                icon: null,
              ),
            ),
        ],
      ),
    );
  }
}
