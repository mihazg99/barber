import 'package:flutter/material.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

class EditBookingFooter extends StatelessWidget {
  const EditBookingFooter({
    super.key,
    required this.canConfirm,
    required this.onConfirm,
    required this.isConfirming,
  });

  final bool canConfirm;
  final VoidCallback onConfirm;
  final bool isConfirming;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: context.appColors.primaryTextColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: context.appSizes.buttonHeightBig,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canConfirm && !isConfirming ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.primaryColor,
              disabledBackgroundColor: context.appColors.captionTextColor
                  .withValues(alpha: 0.25),
              foregroundColor: context.appColors.primaryWhiteColor,
              disabledForegroundColor: context.appColors.captionTextColor
                  .withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  context.appSizes.borderRadius,
                ),
              ),
              elevation: 0,
            ),
            child:
                isConfirming
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.appColors.primaryWhiteColor,
                      ),
                    )
                    : Text(
                      context.l10n.editBookingUpdateButton,
                      style: context.appTextStyles.button.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
