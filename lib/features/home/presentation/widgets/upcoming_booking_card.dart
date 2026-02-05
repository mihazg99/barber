import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
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

/// Upcoming appointment card: horizontal, location + date/time, accent CTA.
class UpcomingBookingCard extends StatelessWidget {
  const UpcomingBookingCard({
    super.key,
    required this.appointment,
    this.locationName,
  });

  final AppointmentEntity appointment;
  final String? locationName;

  static const _cardRadius = 16.0;

  static String _formatDateTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat.yMMMd(locale).format(dt);
    final timeStr = DateFormat.Hm(locale).format(dt);
    return '$dateStr · $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => context.push(
              AppRoute.manageBooking.path.replaceFirst(
                ':appointmentId',
                appointment.appointmentId,
              ),
            ),
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: colors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: colors.borderColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Gap(context.appSizes.paddingMedium),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: colors.primaryColor,
                    size: 22,
                  ),
                ),
                Gap(context.appSizes.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        locationName ?? context.l10n.upcomingAppointment,
                        style: context.appTextStyles.h2.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryTextColor,
                        ),
                      ),
                      Gap(2),
                      Text(
                        _formatDateTime(context, appointment.startTime),
                        style: context.appTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: colors.captionTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _PillButton(
                  label: context.l10n.manage,
                  onPressed:
                      () => context.push(
                        AppRoute.manageBooking.path.replaceFirst(
                          ':appointmentId',
                          appointment.appointmentId,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CTA when user has no upcoming booking. Same card style + "Book" pill.
class NoUpcomingBookingCTA extends StatelessWidget {
  const NoUpcomingBookingCTA({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  static const _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: colors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: colors.borderColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Gap(context.appSizes.paddingMedium),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    color: colors.primaryColor,
                    size: 22,
                  ),
                ),
                Gap(context.appSizes.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.bookYourNextVisit,
                        style: context.appTextStyles.h2.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryTextColor,
                        ),
                      ),
                      Gap(2),
                      Text(
                        context.l10n.chooseLocationServiceTime,
                        style: context.appTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: colors.captionTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _PillButton(label: context.l10n.book, onPressed: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small outlined secondary button; uses brand color (lightened) for contrast on dark cards.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = colors.primaryColorOnDark;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: context.appTextStyles.h2.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accent,
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
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeSectionTitle(title: context.l10n.upcoming),
        Gap(context.appSizes.paddingSmall),
        switch (upcomingAsync) {
          AsyncLoading() => const _UpcomingShimmer(),
          AsyncData(:final value) =>
            value == null
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
    return locations.firstWhere((l) => l.locationId == locationId).name;
  } catch (_) {
    return null;
  }
}

class _UpcomingShimmer extends StatelessWidget {
  const _UpcomingShimmer();

  @override
  Widget build(BuildContext context) {
    const cardRadius = 16.0;
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
              width: 4,
              height: 44,
              borderRadius: BorderRadius.circular(2),
            ),
            Gap(context.appSizes.paddingMedium),
            ShimmerPlaceholder(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(12),
            ),
            Gap(context.appSizes.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerPlaceholder(
                    width: 140,
                    height: 15,
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
              width: 64,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}
