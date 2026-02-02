import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';

class OnboardingPaginationDots extends StatelessWidget {
  const OnboardingPaginationDots({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingSmall / 2,
          ),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                isActive
                    ? context.appColors.primaryColor
                    : context.appColors.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
