import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/extensions/safe_padding_extension.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.brandName,
    this.logoPath,
  });

  final String brandName;
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null && logoPath!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.appSizes.paddingMedium,
        context.safeTopPadding,
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
      ),
      child: Row(
        children: [
          if (hasLogo)
            ClipRRect(
              borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
              child: Image.asset(
                logoPath!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(context),
              ),
            ),
          if (hasLogo) Gap(context.appSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: context.appTextStyles.caption.copyWith(
                    color: context.appColors.captionTextColor,
                  ),
                ),
                Text(
                  brandName,
                  style: context.appTextStyles.h2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      ),
      child: Icon(
        Icons.store,
        color: context.appColors.primaryColor,
        size: 28,
      ),
    );
  }
}
