import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

class BookingLocationSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final LocationEntity location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? context.appColors.primaryColor.withValues(alpha: 0.05)
                    : context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
            border: Border.all(
              color:
                  isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.borderColor.withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.primaryTextColor,
                      ),
                    ),
                    if (location.address.isNotEmpty) ...[
                      Gap(4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
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
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: context.appColors.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
