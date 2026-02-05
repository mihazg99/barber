import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

/// Action buttons for manage booking: reschedule (when canEdit) and cancel.
class ManageBookingActions extends StatelessWidget {
  const ManageBookingActions({
    super.key,
    required this.onCancel,
    required this.appointmentId,
    this.isCancelling = false,
    this.canCancel = true,
    this.canEdit = true,
  });

  final VoidCallback onCancel;
  final String appointmentId;
  final bool isCancelling;
  final bool canCancel;
  /// When false (e.g. barber view), reschedule button is hidden.
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canEdit) ...[
          _RescheduleButton(
            onPressed:
                isCancelling || !canCancel
                    ? null
                    : () => context.push(
                          AppRoute.editBooking.path.replaceFirst(
                            ':appointmentId',
                            appointmentId,
                          ),
                        ),
          ),
          Gap(context.appSizes.paddingSmall),
        ],
        if (!canCancel) ...[
          _CancelPeriodPassedMessage(),
          Gap(context.appSizes.paddingSmall),
        ] else
          _CancelButton(
            onPressed: isCancelling ? null : onCancel,
            isLoading: isCancelling,
          ),
      ],
    );
  }
}

class _CancelPeriodPassedMessage extends StatelessWidget {
  const _CancelPeriodPassedMessage();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: colors.captionTextColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: colors.captionTextColor,
          ),
          Gap(context.appSizes.paddingSmall),
          Expanded(
            child: Text(
              context.l10n.manageBookingCancelPeriodPassed,
              style: context.appTextStyles.caption.copyWith(
                fontSize: 13,
                color: colors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RescheduleButton extends StatelessWidget {
  const _RescheduleButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: context.appSizes.buttonHeightBig,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryColor,
          side: BorderSide(color: colors.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
          ),
        ),
        child: Text(
          context.l10n.manageBookingReschedule,
          style: context.appTextStyles.button.copyWith(
            color: colors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: context.appSizes.buttonHeightBig,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          overlayColor: colors.primaryColor.withValues(alpha: 0.12),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.errorColor,
                  ),
                )
                : Text(
                  context.l10n.manageBookingCancelAppointment,
                  style: context.appTextStyles.button.copyWith(
                    color: colors.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
