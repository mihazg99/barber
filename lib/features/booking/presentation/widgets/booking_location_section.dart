import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

class BookingLocationSection extends HookConsumerWidget {
  const BookingLocationSection({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onLocationSelected,
  });

  final List<LocationEntity> locations;
  final String? selectedLocationId;
  final void Function(LocationEntity) onLocationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          child: Text(
            context.l10n.bookingSelectLocation,
            style: context.appTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.primaryTextColor,
            ),
          ),
        ),
        Gap(context.appSizes.paddingSmall),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          itemCount: locations.length,
          separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
          itemBuilder: (context, index) {
            final location = locations[index];
            final isSelected = location.locationId == selectedLocationId;
            return _LocationCard(
              key: ValueKey(location.locationId),
              location: location,
              isSelected: isSelected,
              onTap: () => onLocationSelected(location),
            );
          },
        ),
      ],
    );
  }
}

class _LocationCard extends HookWidget {
  const _LocationCard({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final LocationEntity location;
  final bool isSelected;
  final VoidCallback onTap;

  static const _animationDuration = Duration(milliseconds: 250);
  static const _animationCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: _animationCurve,
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: isSelected
                ? context.appColors.primaryColor.withValues(alpha: 0.08)
                : context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
            border: Border.all(
              color: isSelected
                  ? context.appColors.primaryColor
                  : context.appColors.borderColor.withValues(alpha: 0.3),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                  BoxShadow(
                    color: context.appColors.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
          ),
          child: Row(
            children: [
              // Icon container with accent color
              AnimatedContainer(
                duration: _animationDuration,
                curve: _animationCurve,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isSelected
                      ? context.appColors.primaryWhiteColor
                      : context.appColors.primaryColor,
                  size: 28,
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: _animationDuration,
                      curve: _animationCurve,
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.appColors.primaryColor
                            : context.appColors.primaryTextColor,
                      ),
                      child: Text(location.name),
                    ),
                    if (location.address.isNotEmpty) ...[
                      Gap(6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: context.appColors.captionTextColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.address,
                              style: context.appTextStyles.caption.copyWith(
                                fontSize: 12,
                                color: context.appColors.captionTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Selection indicator
              AnimatedSwitcher(
                duration: _animationDuration,
                switchInCurve: _animationCurve,
                switchOutCurve: _animationCurve,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: isSelected
                    ? Container(
                        key: const ValueKey('selected'),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.appColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: context.appColors.primaryWhiteColor,
                          size: 16,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('unselected')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
