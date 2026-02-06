import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/di.dart' as home_di;
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

class DashboardLocationsTab extends HookConsumerWidget {
  const DashboardLocationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        final home = ref.read(home_di.homeNotifierProvider);
        final brandId = ref.read(flavorConfigProvider).values.brandConfig.defaultBrandId;
        final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
        final homeHasDataForBrand = home is BaseData<HomeData> &&
            home.data.brand?.brandId == effectiveBrandId;
        if (!homeHasDataForBrand) {
          ref.read(dashboardLocationsNotifierProvider.notifier).load();
        }
      });
      return null;
    }, []);

    final state = ref.watch(dashboardLocationsViewProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          switch (state) {
            BaseInitial() => const _LocationsShimmer(),
            BaseLoading() => const _LocationsShimmer(),
            BaseData(:final data) => _LocationsList(
              locations: data,
              onAdd:
                  () => context.push(
                    AppRoute.dashboardLocationForm.path,
                  ),
              onEdit:
                  (loc) => context.push(
                    AppRoute.dashboardLocationForm.path,
                    extra: loc,
                  ),
              onDelete: (loc) => _confirmDelete(context, ref, loc),
            ),
            BaseError(:final message) => _LocationsError(
              message: message,
              onRetry:
                  () =>
                      ref
                          .read(dashboardLocationsNotifierProvider.notifier)
                          .load(),
            ),
          },
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed:
                  () => context.push(AppRoute.dashboardLocationForm.path),
              backgroundColor: context.appColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LocationEntity location,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.l10n.dashboardLocationDeleteConfirm),
            content: Text(context.l10n.dashboardLocationDeleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: context.appColors.errorColor,
                ),
                child: Text(context.l10n.dashboardLocationDeleteButton),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(dashboardLocationsNotifierProvider.notifier)
          .delete(location.locationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardLocationDeleted),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
      }
    }
  }
}

class _LocationsShimmer extends StatelessWidget {
  const _LocationsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      children: List.generate(
        4,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: context.appSizes.paddingSmall),
          child: ShimmerWrapper(
            variant: ShimmerVariant.dashboard,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: context.appColors.menuBackgroundColor,
                borderRadius: BorderRadius.circular(
                  context.appSizes.borderRadius,
                ),
              ),
              padding: EdgeInsets.all(context.appSizes.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  Gap(context.appSizes.paddingSmall),
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  Gap(4),
                  ShimmerPlaceholder(
                    width: 180,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationsList extends StatelessWidget {
  const _LocationsList({
    required this.locations,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LocationEntity> locations;
  final VoidCallback onAdd;
  final void Function(LocationEntity) onEdit;
  final void Function(LocationEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.dashboardLocationEmpty,
                textAlign: TextAlign.center,
                style: context.appTextStyles.medium.copyWith(
                  color: context.appColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        return _LocationCard(
          location: loc,
          onTap: () => onEdit(loc),
          onDelete: () => onDelete(loc),
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onTap,
    required this.onDelete,
  });

  final LocationEntity location;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

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

    return Card(
      margin: EdgeInsets.only(bottom: context.appSizes.paddingSmall),
      color: context.appColors.menuBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Row(
            children: [
              Expanded(
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
                        fontSize: 16,
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
                          fontSize: 12,
                          color: context.appColors.captionTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: context.appColors.errorColor,
                  size: 22,
                ),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationsError extends StatelessWidget {
  const _LocationsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.appColors.errorColor,
            ),
            Gap(context.appSizes.paddingMedium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.appTextStyles.medium.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
            ),
            Gap(context.appSizes.paddingMedium),
            PrimaryButton.small(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
