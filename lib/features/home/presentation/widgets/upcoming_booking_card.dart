import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Upcoming appointment card: horizontal, location + date/time, white "Book" pill.
class UpcomingBookingCard extends StatelessWidget {
  const UpcomingBookingCard({
    super.key,
    required this.appointment,
    this.locationName,
  });

  final AppointmentEntity appointment;
  final String? locationName;

  static const _cardRadius = 20.0;

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour;
    final m = dt.minute;
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final period = h >= 12 ? 'PM' : 'AM';
    final min = m.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoute.booking.path),
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: context.appColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.appColors.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: context.appColors.primaryColor,
                  size: 26,
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      locationName ?? 'Upcoming appointment',
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.primaryTextColor,
                      ),
                    ),
                    Gap(4),
                    Text(
                      _formatDateTime(appointment.startTime),
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              _PillButton(
                label: 'Manage',
                onPressed: () => context.push(AppRoute.booking.path),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CTA when user has no upcoming booking. Same card style + white "Book" pill.
class NoUpcomingBookingCTA extends StatelessWidget {
  const NoUpcomingBookingCTA({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  static const _cardRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: context.appColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.appColors.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: context.appColors.primaryColor,
                  size: 26,
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book your next visit',
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.primaryTextColor,
                      ),
                    ),
                    Gap(4),
                    Text(
                      'Choose location, service and time',
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              _PillButton(label: 'Book', onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// White pill CTA (e.g. "Book", "Manage", "Book Now").
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.primaryWhiteColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
          child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium + 4,
            vertical: context.appSizes.paddingSmall + 2,
          ),
          child: Text(
            label,
            style: context.appTextStyles.h2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appColors.secondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

const _upcomingSectionSpacing = 28.0;

/// Upcoming booking block on home: shimmer when loading, card or CTA when loaded.
/// Same pattern as [LocationsList] — one main widget + shimmer.
class UpcomingBooking extends ConsumerWidget {
  const UpcomingBooking({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentProvider);
    final homeState = ref.watch(homeNotifierProvider);
    final locations =
        homeState is BaseData<HomeData> ? homeState.data.locations : <LocationEntity>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const HomeSectionTitle(title: 'Upcoming'),
        Gap(context.appSizes.paddingSmall),
        switch (upcomingAsync) {
          AsyncLoading() => const _UpcomingShimmer(),
          AsyncData(:final value) => value == null
              ? NoUpcomingBookingCTA(
                  onTap: () => context.push(AppRoute.booking.path),
                )
              : UpcomingBookingCard(
                  appointment: value,
                  locationName: _locationNameFor(locations, value.locationId),
                ),
          _ => NoUpcomingBookingCTA(
              onTap: () => context.push(AppRoute.booking.path),
            ),
        },
        Gap(_upcomingSectionSpacing),
      ],
    );
  }
}

String? _locationNameFor(List<LocationEntity> locations, String locationId) {
  try {
    return locations
        .firstWhere((l) => l.locationId == locationId)
        .name;
  } catch (_) {
    return null;
  }
}

class _UpcomingShimmer extends StatelessWidget {
  const _UpcomingShimmer();

  @override
  Widget build(BuildContext context) {
    const cardRadius = 20.0;
    return ShimmerWrapper(
      child: Container(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        decoration: BoxDecoration(
          color: context.appColors.menuBackgroundColor,
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: 52,
              height: 52,
              borderRadius: BorderRadius.circular(14),
            ),
            Gap(context.appSizes.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerPlaceholder(
                    width: 140,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  Gap(4),
                  ShimmerPlaceholder(
                    width: 100,
                    height: 13,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            ShimmerPlaceholder(
              width: 72,
              height: 36,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ),
      ),
    );
  }
}
