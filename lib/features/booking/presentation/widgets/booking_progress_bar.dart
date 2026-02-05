import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';

class BookingProgressBar extends StatelessWidget {
  const BookingProgressBar({
    super.key,
    this.showLocationStep = false,
    this.locationSelected = false,
    required this.serviceSelected,
    required this.barberSelected,
    required this.timeSelected,
  });

  final bool showLocationStep;
  final bool locationSelected;
  final bool serviceSelected;
  final bool barberSelected;
  final bool timeSelected;

  @override
  Widget build(BuildContext context) {
    // Only the current (first incomplete) step is "active"; all future steps use muted style.
    final locationActive = showLocationStep && !locationSelected;
    final serviceActive = _serviceUnlocked && !serviceSelected;
    final barberActive = _serviceUnlocked && serviceSelected && !barberSelected;
    final timeActive = barberSelected && !timeSelected;

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
              if (showLocationStep) ...[
                _StepIndicator(
                  label: context.l10n.bookingStepLocation,
                  isCompleted: locationSelected,
                  isActive: locationActive,
                ),
                _Connector(isCompleted: locationSelected),
              ],
              _StepIndicator(
                label: context.l10n.bookingStepService,
                isCompleted: serviceSelected,
                isActive: serviceActive,
              ),
              _Connector(isCompleted: serviceSelected),
              _StepIndicator(
                label: context.l10n.bookingStepBarber,
                isCompleted: barberSelected,
                isActive: barberActive,
              ),
              _Connector(isCompleted: barberSelected),
              _StepIndicator(
                label: context.l10n.bookingStepTime,
                isCompleted: timeSelected,
                isActive: timeActive,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _serviceUnlocked {
    if (showLocationStep) return locationSelected;
    return true;
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

  static const _duration = Duration(milliseconds: 280);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted || isActive
            ? context.appColors.primaryColor
            : context.appColors.captionTextColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: _duration,
          curve: _curve,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isCompleted
                    ? context.appColors.primaryColor
                    : Colors.transparent,
            border: Border.all(color: color, width: 2),
            boxShadow:
                isActive && !isCompleted
                    ? [
                      BoxShadow(
                        color: context.appColors.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ]
                    : null,
          ),
          child: AnimatedSwitcher(
            duration: _duration,
            switchInCurve: _curve,
            switchOutCurve: _curve,
            child:
                isCompleted
                    ? Icon(
                      Icons.check,
                      key: const ValueKey('check'),
                      size: 14,
                      color: context.appColors.primaryWhiteColor,
                    )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: _duration,
          curve: _curve,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                isActive || isCompleted ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.isCompleted});

  final bool isCompleted;

  static const _duration = Duration(milliseconds: 280);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
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
