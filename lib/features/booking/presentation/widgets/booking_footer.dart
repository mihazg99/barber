import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:gap/gap.dart';

class BookingFooter extends StatelessWidget {
  const BookingFooter({
    super.key,
    required this.totalPrice,
    required this.totalDurationMinutes,
    required this.canConfirm,
    required this.onConfirm,
    required this.isConfirming,
  });

  final num totalPrice;
  final int totalDurationMinutes;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final bool isConfirming;

  String _formatPrice(BuildContext context, num price) =>
      context.formatPriceWithCurrency(price);

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.bookingTotal,
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: context.appColors.captionTextColor,
                    ),
                  ),
                  Gap(2),
                  Row(
                    children: [
                      Text(
                        _formatPrice(context, totalPrice),
                        style: context.appTextStyles.h1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.appColors.captionTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(totalDurationMinutes),
                        style: context.appTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: context.appColors.captionTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: SizedBox(
                height: context.appSizes.buttonHeightBig,
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
                    minimumSize: const Size(140, 56),
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
                          : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              context.l10n.bookingConfirm,
                              style: context.appTextStyles.button.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
