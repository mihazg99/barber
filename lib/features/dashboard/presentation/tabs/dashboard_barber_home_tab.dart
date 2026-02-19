import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
import 'package:barber/features/home/presentation/widgets/upcoming_booking_card.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Barber dashboard home tab: greeting, QR scan CTA, today/future appointments stream.
class DashboardBarberHomeTab extends HookConsumerWidget {
  const DashboardBarberHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final lastUser = ref.watch(lastSignedInUserProvider);
    final user = userAsync.valueOrNull ?? lastUser;
    final appointmentsAsync = ref.watch(calendarWindowAppointmentsProvider);
    final homeState = ref.watch(homeNotifierProvider);
    final tabNotifier = ref.read(dashboardBarberTabIndexProvider.notifier);
    final locations =
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];
    final isLocationsLoading = homeState is BaseLoading;

    // Home data loaded centrally by DashboardPage when barber dashboard mounts.
    final firstName = _firstName(user?.fullName);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(calendarWindowAppointmentsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.appSizes.paddingMedium,
          vertical: context.appSizes.paddingSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarberHomeHeader(firstName: firstName),
            SizedBox(height: context.appSizes.paddingMedium),
            _ScanHeroCard(
              onTap: () => context.push(AppRoute.dashboardRedeemReward.path),
            ),
            SizedBox(height: context.appSizes.paddingLarge),
            HomeSectionTitle(title: context.l10n.upcoming),
            SizedBox(height: context.appSizes.paddingSmall),
            switch (appointmentsAsync) {
              AsyncLoading() => Builder(
                builder: (context) {
                  return const _TodayShimmer();
                },
              ),
              AsyncData(:final value) => Builder(
                builder: (context) {
                  // Check if we have a barber profile issue
                  final barberAsync = ref.watch(currentBarberProvider);
                  // If user has no barberId AND currentBarberProvider returned null (data is null), then we have no profile.
                  if ((user?.barberId.isEmpty ?? true) &&
                      barberAsync.asData?.value == null &&
                      !barberAsync.isLoading) {
                    return Container(
                      padding: EdgeInsets.all(context.appSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: context.appColors.errorColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          context.appSizes.borderRadius,
                        ),
                        border: Border.all(
                          color: context.appColors.errorColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.noBarberProfileTitle,
                            style: context.appTextStyles.h3.copyWith(
                              color: context.appColors.errorColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.noBarberProfileMessage,
                            style: context.appTextStyles.body.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final upcomingToday =
                      value
                          .where((a) {
                            final isToday =
                                a.startTime.year == now.year &&
                                a.startTime.month == now.month &&
                                a.startTime.day == now.day;
                            return isToday && a.startTime.isAfter(now);
                          })
                          .take(3)
                          .toList();

                  if (upcomingToday.isEmpty) {
                    return _TodayEmptyCard(
                      onViewBookings: () => tabNotifier.state = 1,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...upcomingToday.map(
                        (a) => Padding(
                          padding: EdgeInsets.only(
                            bottom: context.appSizes.paddingSmall,
                          ),
                          child: UpcomingBookingCard(
                            appointment: a,
                            locationName: _locationNameFor(
                              locations,
                              a.locationId,
                            ),
                            isLocationsLoading: isLocationsLoading,
                            isProfessionalView: true,
                          ),
                        ),
                      ),
                      _ViewBookingsCta(
                        onTap: () => tabNotifier.state = 1,
                      ),
                    ],
                  );
                },
              ),
              AsyncError() => Builder(
                builder: (context) {
                  return _TodayEmptyCard(
                    onViewBookings: () => tabNotifier.state = 1,
                  );
                },
              ),
              _ => _TodayEmptyCard(onViewBookings: () => tabNotifier.state = 1),
            },
            SizedBox(height: context.appSizes.paddingLarge),
          ],
        ),
      ),
    );
  }

  static String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  static String? _locationNameFor(
    List<LocationEntity> locations,
    String locationId,
  ) {
    try {
      return locations.firstWhere((l) => l.locationId == locationId).name;
    } catch (_) {
      return null;
    }
  }
}

/// Barber home header: "Hey, {name} 👋" and date. No brand name below app bar.
class _BarberHomeHeader extends StatelessWidget {
  const _BarberHomeHeader({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.appTextStyles;
    final sizes = context.appSizes;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat('EEEE, MMMM d', locale).format(DateTime.now());

    final displayName = firstName.trim().isEmpty ? '' : firstName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName.isEmpty
              ? context.l10n.barberHomeHey
              : context.l10n.barberHomeHeyName(displayName),
          style: styles.bold.copyWith(
            fontSize: 28,
            color: colors.primaryTextColor,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: sizes.paddingSmall / 2),
        Text(
          dateStr,
          style: styles.caption.copyWith(
            fontSize: 14,
            color: colors.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.appTextStyles;
    final sizes = context.appSizes;

    return Material(
      color: colors.primaryColor,
      borderRadius: BorderRadius.circular(sizes.borderRadius + 4),
      elevation: 4,
      shadowColor: colors.primaryColor.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sizes.borderRadius + 4),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.paddingLarge,
            vertical: sizes.paddingXl,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primaryWhiteColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 48,
                  color: colors.primaryWhiteColor,
                ),
              ),
              SizedBox(height: sizes.paddingMedium),
              Text(
                context.l10n.barberHomeScanCta,
                style: styles.bold.copyWith(
                  fontSize: 22,
                  color: colors.primaryWhiteColor,
                ),
              ),
              SizedBox(height: sizes.paddingSmall / 2),
              Text(
                context.l10n.barberHomeScanSubtitle,
                style: styles.caption.copyWith(
                  fontSize: 13,
                  color: colors.primaryWhiteColor.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayShimmer extends StatelessWidget {
  const _TodayShimmer();

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    return ShimmerWrapper(
      child: Container(
        padding: EdgeInsets.all(sizes.paddingMedium),
        decoration: BoxDecoration(
          color: context.appColors.menuBackgroundColor,
          borderRadius: BorderRadius.circular(sizes.borderRadius),
        ),
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(10),
            ),
            SizedBox(width: sizes.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder(
                    width: 120,
                    height: 15,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 6),
                  ShimmerPlaceholder(
                    width: 80,
                    height: 13,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayEmptyCard extends StatelessWidget {
  const _TodayEmptyCard({required this.onViewBookings});

  final VoidCallback onViewBookings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;

    return Material(
      color: colors.menuBackgroundColor,
      borderRadius: BorderRadius.circular(sizes.borderRadius),
      child: InkWell(
        onTap: onViewBookings,
        borderRadius: BorderRadius.circular(sizes.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(sizes.paddingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.today_rounded,
                  size: 24,
                  color: colors.primaryColor,
                ),
              ),
              SizedBox(width: sizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.barberHomeUpcomingCardTitle,
                      style: context.appTextStyles.medium.copyWith(
                        fontSize: 15,
                        color: colors.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.l10n.barberHomeUpcomingEmpty,
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: colors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryTextColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewBookingsCta extends StatelessWidget {
  const _ViewBookingsCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    return Padding(
      padding: EdgeInsets.only(top: sizes.paddingSmall),
      child: Material(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(sizes.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(sizes.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(sizes.paddingMedium),
            child: Row(
              children: [
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.appColors.primaryColor,
                  size: 24,
                ),
                SizedBox(width: sizes.paddingSmall),
                Text(
                  context.l10n.barberHomeViewBookings,
                  style: context.appTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.appColors.primaryColor,
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
