import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/stats/domain/entities/dashboard_stats_entity.dart';

/// SuperAdmin Analytics tab: location selector + Marketing Insights from pre-aggregated stats.
/// Stats are loaded on demand only when the tab is selected (avoids unnecessary Firestore reads).
class DashboardAnalyticsTab extends HookConsumerWidget {
  const DashboardAnalyticsTab({super.key, this.isSelected = false});

  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsState = ref.watch(dashboardLocationsViewProvider);
    final selectedLocationId = useState<String?>(null);
    final cachedLocations = useState<List<LocationEntity>>([]);

    useEffect(() {
      if (locationsState is BaseData<List<LocationEntity>> &&
          locationsState.data.isNotEmpty) {
        cachedLocations.value = locationsState.data;
      }
      return null;
    }, [locationsState]);

    final locations = locationsState is BaseData<List<LocationEntity>>
        ? locationsState.data
        : cachedLocations.value;

    final locationId = selectedLocationId.value ??
        (locations.isNotEmpty ? locations.first.locationId : null);
    // Only fetch stats when tab is selected. Empty locationId = no Firestore read.
    final effectiveLocationId = isSelected ? (locationId ?? '') : '';
    final statsAsync = ref.watch(dashboardStatsProvider(effectiveLocationId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(dashboardLocationsNotifierProvider.notifier)
              .load();
          ref.invalidate(dashboardStatsProvider(locationId ?? ''));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
            vertical: context.appSizes.paddingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationSelector(
                locations: locations,
                selectedLocationId: selectedLocationId.value,
                onLocationChanged: (id) => selectedLocationId.value = id,
              ),
              SizedBox(height: context.appSizes.paddingLarge),
              _MarketingInsightsSection(
                statsAsync: statsAsync,
                currencyCode:
                    ref.read(flavorConfigProvider).values.brandConfig.currency,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.locations,
    required this.selectedLocationId,
    required this.onLocationChanged,
  });

  final List<LocationEntity> locations;
  final String? selectedLocationId;
  final void Function(String?) onLocationChanged;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.addItemSelectLocation,
          style: context.appTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.appColors.secondaryTextColor,
          ),
        ),
        SizedBox(height: context.appSizes.paddingSmall),
        DropdownButtonFormField<String>(
          value: selectedLocationId ?? locations.first.locationId,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appColors.menuBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
            ),
          ),
          items: locations
              .map(
                (l) => DropdownMenuItem(
                  value: l.locationId,
                  child: Text(l.name),
                ),
              )
              .toList(),
          onChanged: onLocationChanged,
        ),
      ],
    );
  }
}

class _MarketingInsightsSection extends StatelessWidget {
  const _MarketingInsightsSection({
    required this.statsAsync,
    required this.currencyCode,
  });

  final AsyncValue<Either<Object, DashboardStatsEntity>> statsAsync;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return switch (statsAsync) {
      AsyncLoading() => const _MarketingInsightsShimmer(),
      AsyncData(:final value) => value.fold(
            (_) => const SizedBox.shrink(),
            (stats) => _MarketingInsightsCard(
              stats: stats,
              currencyCode: currencyCode,
            ),
          ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _MarketingInsightsCard extends StatelessWidget {
  const _MarketingInsightsCard({
    required this.stats,
    required this.currencyCode,
  });

  final DashboardStatsEntity stats;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.appTextStyles;
    final sizes = context.appSizes;
    final l10n = context.l10n;

    final daily = stats.dailyStats;
    final avgTicket =
        stats.averageTicketValueToday ?? stats.averageTicketValueMonthly;

    if (daily == null && avgTicket == null) {
      return Material(
        color: colors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(sizes.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(sizes.paddingMedium),
          child: Text(
            l10n.marketingInsightsTitle,
            style: styles.bold.copyWith(
              fontSize: 16,
              color: colors.primaryTextColor,
            ),
          ),
        ),
      );
    }

    return Material(
      color: colors.menuBackgroundColor,
      borderRadius: BorderRadius.circular(sizes.borderRadius),
      child: Padding(
        padding: EdgeInsets.all(sizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.marketingInsightsTitle,
              style: styles.bold.copyWith(
                fontSize: 16,
                color: colors.primaryTextColor,
              ),
            ),
            SizedBox(height: sizes.paddingSmall),
            if (avgTicket != null)
              _StatRow(
                label: l10n.averageTicketValue,
                value: formatPrice(avgTicket, currencyCode),
              ),
            if (daily != null) ...[
              if (daily.totalRevenue > 0 || daily.appointmentsCount > 0) ...[
                if (avgTicket != null) SizedBox(height: sizes.paddingSmall / 2),
                _StatRow(
                  label: l10n.todayRevenue,
                  value: formatPrice(daily.totalRevenue, currencyCode),
                ),
                _StatRow(
                  label: l10n.todayAppointments,
                  value: '${daily.appointmentsCount}',
                ),
              ],
              if (daily.newCustomers > 0 || daily.noShows > 0) ...[
                SizedBox(height: sizes.paddingSmall / 2),
                if (daily.newCustomers > 0)
                  _StatRow(
                    label: l10n.newCustomersToday,
                    value: '${daily.newCustomers}',
                  ),
                if (daily.noShows > 0)
                  _StatRow(
                    label: l10n.noShowsToday,
                    value: '${daily.noShows}',
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.appTextStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: styles.caption.copyWith(
              fontSize: 13,
              color: colors.secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: styles.medium.copyWith(
              fontSize: 14,
              color: colors.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketingInsightsShimmer extends StatelessWidget {
  const _MarketingInsightsShimmer();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(
              width: 140,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: sizes.paddingSmall),
            ShimmerPlaceholder(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 4),
            ShimmerPlaceholder(
              width: 120,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
