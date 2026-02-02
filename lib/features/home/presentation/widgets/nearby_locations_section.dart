import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Section title + grid of location cards with image placeholder, hours, "Book Now" pill.
class NearbyLocationsSection extends StatelessWidget {
  const NearbyLocationsSection({
    super.key,
    required this.locations,
    this.title = 'NEARBY BARBERSHOP',
  });

  final List<LocationEntity> locations;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(title: title),
        Gap(context.appSizes.paddingSmall),
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 2;
            final spacing = context.appSizes.paddingSmall;
            final width =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: locations
                  .take(6)
                  .map((loc) => SizedBox(
                        width: width,
                        child: _LocationCard(location: loc),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

const _cardRadius = 20.0;

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final LocationEntity location;

  static const _dayKeys = [
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
  ];

  String _todayHours(WorkingHoursMap hours) {
    final today = DateTime.now().weekday;
    final key = _dayKeys[today - 1];
    final day = hours[key];
    if (day == null) return 'Closed';
    return 'OPEN NOW ${day.open} - ${day.close}';
  }

  @override
  Widget build(BuildContext context) {
    final hoursLine = _todayHours(location.workingHours);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoute.booking.path),
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: context.appColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_cardRadius),
                ),
                child: AspectRatio(
                  aspectRatio: 1.4,
                  child: Container(
                    color: context.appColors.borderColor.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.store_rounded,
                      size: 40,
                      color: context.appColors.captionTextColor.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.appSizes.paddingSmall + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hoursLine,
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hoursLine.startsWith('OPEN')
                            ? context.appColors.primaryColor
                            : context.appColors.captionTextColor,
                      ),
                    ),
                    Gap(4),
                    Text(
                      location.name,
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.primaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.address.isNotEmpty) ...[
                      Gap(2),
                      Text(
                        location.address,
                        style: context.appTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: context.appColors.captionTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    Gap(context.appSizes.paddingSmall),
                    _BookNowPill(onTap: () => context.push(AppRoute.booking.path)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookNowPill extends StatelessWidget {
  const _BookNowPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.primaryWhiteColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.appSizes.paddingSmall,
            ),
            child: Text(
              'Book Now',
              style: context.appTextStyles.h2.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appColors.secondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
