import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';

class BookingProgressBar extends StatelessWidget {
  const BookingProgressBar({
    super.key,
    required this.serviceSelected,
    required this.barberSelected,
    required this.timeSelected,
  });

  final bool serviceSelected;
  final bool barberSelected;
  final bool timeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.appSizes.paddingMedium,
        vertical: context.appSizes.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepIndicator(
                label: context.l10n.bookingStepService,
                isCompleted: serviceSelected,
                isActive: !serviceSelected,
              ),
              _Connector(isCompleted: serviceSelected),
              _StepIndicator(
                label: context.l10n.bookingStepBarber,
                isCompleted: barberSelected,
                isActive: serviceSelected && !barberSelected,
              ),
              _Connector(isCompleted: barberSelected),
              _StepIndicator(
                label: context.l10n.bookingStepTime,
                isCompleted: timeSelected,
                isActive: barberSelected && !timeSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  final String label;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted || isActive
            ? context.appColors.primaryColor
            : context.appColors.captionTextColor;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isCompleted
                    ? context.appColors.primaryColor
                    : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child:
              isCompleted
                  ? Icon(
                    Icons.check,
                    size: 14,
                    color: context.appColors.primaryWhiteColor,
                  )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                isActive || isCompleted ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color:
            isCompleted
                ? context.appColors.primaryColor
                : context.appColors.captionTextColor.withValues(alpha: 0.3),
      ),
    );
  }
}
