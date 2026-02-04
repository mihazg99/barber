import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

class BookingPreSelectionChip extends StatelessWidget {
  const BookingPreSelectionChip({
    super.key,
    required this.barberName,
    required this.onClear,
  });

  final String barberName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.appSizes.paddingMedium,
        vertical: context.appSizes.paddingSmall,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.appSizes.paddingSmall,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: context.appColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.appColors.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.bookingWithBarber(barberName),
              style: context.appTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.appColors.primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: context.appColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
