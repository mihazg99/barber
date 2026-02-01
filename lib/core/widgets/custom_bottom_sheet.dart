import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/core/theme/app_text_styles.dart';

class CustomBottomSheet extends StatelessWidget {
  const CustomBottomSheet({
    super.key,
    required this.content,
    required this.title,
  });

  final Widget content;
  final String title;

  /// Show the bottom sheet as a modal
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: context.appColors.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.appSizes.borderRadius),
                topRight: Radius.circular(context.appSizes.borderRadius),
              ),
            ),
            child: CustomBottomSheet(
              title: title,
              content: content,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColors.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.appSizes.borderRadius),
          topRight: Radius.circular(context.appSizes.borderRadius),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: context.appSizes.paddingLarge,
          right: context.appSizes.paddingLarge,
          top: context.appSizes.paddingLarge,
          bottom:
              context.appSizes.paddingLarge +
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Gap(context.appSizes.paddingMedium),
            // Title
            Center(
              child: Text(
                title,
                style: context.appTextStyles.h2,
              ),
            ),
            Gap(context.appSizes.paddingMedium),
            content,
            // Bottom padding for safe area (removed since it's now in the padding)
          ],
        ),
      ),
    );
  }
}
