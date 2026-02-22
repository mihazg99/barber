import 'package:flutter/material.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/gen/assets.gen.dart';

class FilterButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FilterButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        context.appSizes.borderRadius,
      ),
      child: Ink(
        padding: EdgeInsets.all(context.appSizes.paddingSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            context.appSizes.borderRadius,
          ),
          color: context.appColors.menuBackgroundColor,
        ),
        child: Assets.icons.filter.svg(),
      ),
    );
  }
} 