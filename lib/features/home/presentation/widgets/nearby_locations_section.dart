import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Nearby locations on home: shimmer when loading, grid when loaded.
/// Same pattern as [LocationsList] — one main widget + shimmer.
class NearbyLocationsSection extends ConsumerWidget {
  const NearbyLocationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return switch (homeState) {
      BaseInitial() => const _NearbyLocationsShimmer(),
      BaseLoading() => const _NearbyLocationsShimmer(),
      BaseData(:final data) => _NearbyLocationsContent(
        locations: data.locations,
        title: context.l10n.sectionNearbyBarbershop,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Section title + grid of location cards with image placeholder, hours, "Book Now" pill.
class _NearbyLocationsContent extends StatelessWidget {
  const _NearbyLocationsContent({
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
              children:
                  locations
                      .take(6)
                      .map(
                        (loc) => SizedBox(
                          width: width,
                          child: _LocationCard(location: loc),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NearbyLocationsShimmer extends StatelessWidget {
  const _NearbyLocationsShimmer();

  @override
  Widget build(BuildContext context) {
    const cardRadius = 20.0;
    final spacing = context.appSizes.paddingSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(title: context.l10n.sectionNearbyBarbershop),
        Gap(context.appSizes.paddingSmall),
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 2;
            final width =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                4,
                (_) => SizedBox(
                  width: width,
                  child: ShimmerWrapper(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.appColors.menuBackgroundColor,
                        borderRadius: BorderRadius.circular(cardRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.appColors.menuBackgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(cardRadius),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(
                              context.appSizes.paddingSmall + 2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerPlaceholder(
                                  width: 80,
                                  height: 10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                Gap(4),
                                ShimmerPlaceholder(
                                  width: double.infinity,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                Gap(context.appSizes.paddingSmall),
                                ShimmerPlaceholder(
                                  width: 70,
                                  height: 28,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun',
  ];

  String _todayHours(BuildContext context, WorkingHoursMap hours) {
    final today = DateTime.now().weekday;
    final key = _dayKeys[today - 1];
    final day = hours[key];
    if (day == null) return context.l10n.closed;
    return context.l10n.openNow(day.open, day.close);
  }

  @override
  Widget build(BuildContext context) {
    final hoursLine = _todayHours(context, location.workingHours);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '${AppRoute.booking.path}?locationId=${location.locationId}',
        ),
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
                        color:
                            hoursLine != context.l10n.closed
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
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: context.appColors.captionTextColor,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location.address,
                              style: context.appTextStyles.caption.copyWith(
                                fontSize: 11,
                                color: context.appColors.captionTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Gap(context.appSizes.paddingSmall),
                    _BookNowPill(
                      onTap: () => context.push(
                        '${AppRoute.booking.path}?locationId=${location.locationId}',
                      ),
                    ),
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
              context.l10n.bookNow,
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
