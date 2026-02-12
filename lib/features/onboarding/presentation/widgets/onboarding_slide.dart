import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/glass_container.dart';
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
          // Glass icon container
          GlassContainer(
            borderRadius: context.appSizes.borderRadius * 1.5,
            backgroundColor: context.appColors.primaryColor.withValues(
              alpha: 0.12,
            ),
            borderColor: context.appColors.primaryColor.withValues(alpha: 0.3),
            boxShadow: [
              BoxShadow(
                color: context.appColors.primaryColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            child: SizedBox(
              width: 120,
              height: 120,
              child: Center(
                child: Icon(
                  IconData(page.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 64,
                  color: context.appColors.primaryColor,
                ),
              ),
            ),
          ),
          Gap(context.appSizes.paddingXxl),

          // Glass text container
          GlassContainer(
            borderRadius: context.appSizes.borderRadius * 1.5,
            padding: EdgeInsets.all(context.appSizes.paddingLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: context.appTextStyles.headline.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(context.appSizes.paddingMedium),
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: context.appTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
