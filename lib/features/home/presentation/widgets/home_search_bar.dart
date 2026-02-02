import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Full-width search bar with magnifying glass and placeholder.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    this.onTap,
    this.hint = 'Search',
  });

  final VoidCallback? onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
            vertical: context.appSizes.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.appColors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 22,
                color: context.appColors.captionTextColor,
              ),
              SizedBox(width: context.appSizes.paddingSmall),
              Expanded(
                child: Text(
                  hint,
                  style: context.appTextStyles.body.copyWith(
                    color: context.appColors.hintTextColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
