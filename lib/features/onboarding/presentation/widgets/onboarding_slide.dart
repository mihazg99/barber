import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_page_entity.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.page,
  });

  final OnboardingPageEntity page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.appColors.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius * 1.5,
              ),
            ),
            child: Icon(
              IconData(page.iconCodePoint, fontFamily: 'MaterialIcons'),
              size: 64,
              color: context.appColors.primaryColor,
            ),
          ),
          Gap(context.appSizes.paddingXxl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.appTextStyles.headline.copyWith(
              color: context.appColors.primaryTextColor,
              fontSize: 22,
            ),
          ),
          Gap(context.appSizes.paddingMedium),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: context.appTextStyles.body.copyWith(
              color: context.appColors.secondaryTextColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
