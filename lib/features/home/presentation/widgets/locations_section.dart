import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

class LocationsSection extends StatelessWidget {
  const LocationsSection({
    super.key,
    required this.locations,
  });

  final List<LocationEntity> locations;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Locations',
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          ...locations
              .take(3)
              .map(
                (loc) => Padding(
                  padding: EdgeInsets.only(
                    bottom: context.appSizes.paddingSmall,
                  ),
                  child: _LocationCard(location: loc),
                ),
              ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final LocationEntity location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        border: Border.all(color: context.appColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: context.appColors.primaryColor,
            size: 20,
          ),
          Gap(context.appSizes.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: context.appTextStyles.h2.copyWith(
                    color: context.appColors.primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (location.address.isNotEmpty) ...[
                  Gap(context.appSizes.paddingSmall / 2),
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
                            color: context.appColors.captionTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
