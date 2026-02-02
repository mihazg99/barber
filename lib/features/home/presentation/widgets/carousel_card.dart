import 'package:flutter/material.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

class CarouselCard extends StatelessWidget {
  final String text;
  final bool isFirst;

  const CarouselCard({super.key, required this.text, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      vertical: context.appSizes.paddingSmall,
      horizontal: context.appSizes.paddingMedium,
    );
    
    final gradientColors = isFirst
        ? [
            context.appColors.primaryColor.withValues(alpha: 0.9),
            context.appColors.primaryColor.withValues(alpha: 0.7),
          ]
        : [
            context.appColors.primaryColor.withValues(alpha: 0.6),
            context.appColors.secondaryColor,
          ];

    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        color: context.appColors.backgroundColor,
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(text, style: context.appTextStyles.caption),
            ),
          ),
        ],
      ),
    );
  }
}
