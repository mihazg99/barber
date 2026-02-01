import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
            border: Border.all(color: context.appColors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.appColors.primaryColor.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(context.appSizes.borderRadius / 2),
                ),
                child: Icon(icon, color: context.appColors.primaryColor),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: Text(
                  title,
                  style: context.appTextStyles.h2.copyWith(
                    color: context.appColors.primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: context.appColors.captionTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
