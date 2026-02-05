import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Superadmin barbers tab. List, add, edit, delete barbers.
class DashboardBarbersTab extends HookConsumerWidget {
  const DashboardBarbersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(dashboardBarbersNotifierProvider.notifier).load();
        ref.read(dashboardLocationsNotifierProvider.notifier).load();
      });
      return null;
    }, []);

    final state = ref.watch(dashboardBarbersNotifierProvider);
    final locationsState = ref.watch(dashboardLocationsNotifierProvider);
    final locations =
        locationsState is BaseData<List<LocationEntity>>
            ? locationsState.data
            : <LocationEntity>[];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          switch (state) {
            BaseInitial() => const _BarbersShimmer(),
            BaseLoading() => const _BarbersShimmer(),
            BaseData(:final data) => _BarbersList(
              barbers: data,
              locations: locations,
              onAdd: () => context.push(AppRoute.dashboardBarberForm.path),
              onEdit:
                  (b) => context.push(
                    AppRoute.dashboardBarberForm.path,
                    extra: b,
                  ),
              onDelete: (b) => _confirmDelete(context, ref, b),
            ),
            BaseError(:final message) => _BarbersError(
              message: message,
              onRetry:
                  () =>
                      ref
                          .read(dashboardBarbersNotifierProvider.notifier)
                          .load(),
            ),
          },
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoute.dashboardBarberForm.path),
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
    BarberEntity barber,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.l10n.dashboardBarberDeleteConfirm),
            content: Text(context.l10n.dashboardBarberDeleteConfirmMessage),
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
                child: Text(context.l10n.dashboardBarberDeleteButton),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(dashboardBarbersNotifierProvider.notifier)
          .delete(barber.barberId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardBarberDeleted),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
      }
    }
  }
}

class _BarbersShimmer extends StatelessWidget {
  const _BarbersShimmer();

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
              height: 80,
              decoration: BoxDecoration(
                color: context.appColors.menuBackgroundColor,
                borderRadius: BorderRadius.circular(
                  context.appSizes.borderRadius,
                ),
              ),
              padding: EdgeInsets.all(context.appSizes.paddingMedium),
              child: Row(
                children: [
                  ShimmerPlaceholder(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  Gap(context.appSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerPlaceholder(
                          width: 140,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        Gap(6),
                        ShimmerPlaceholder(
                          width: 100,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
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
  }
}

class _BarbersList extends StatelessWidget {
  const _BarbersList({
    required this.barbers,
    required this.locations,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<BarberEntity> barbers;
  final List<LocationEntity> locations;
  final VoidCallback onAdd;
  final void Function(BarberEntity) onEdit;
  final void Function(BarberEntity) onDelete;

  String _locationName(String locationId) {
    for (final loc in locations) {
      if (loc.locationId == locationId) return loc.name;
    }
    return locationId;
  }

  @override
  Widget build(BuildContext context) {
    if (barbers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.dashboardBarberEmpty,
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
      itemCount: barbers.length,
      itemBuilder: (context, index) {
        final barber = barbers[index];
        return _BarberCard(
          barber: barber,
          locationName: _locationName(barber.locationId),
          onTap: () => onEdit(barber),
          onDelete: () => onDelete(barber),
        );
      },
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.locationName,
    required this.onTap,
    required this.onDelete,
  });

  final BarberEntity barber;
  final String locationName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 28,
                backgroundColor: context.appColors.primaryColor.withValues(
                  alpha: 0.15,
                ),
                backgroundImage:
                    barber.photoUrl.isNotEmpty
                        ? NetworkImage(barber.photoUrl)
                        : null,
                child:
                    barber.photoUrl.isEmpty
                        ? Icon(
                          Icons.person,
                          size: 32,
                          color: context.appColors.primaryColor,
                        )
                        : null,
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            barber.name,
                            style: context.appTextStyles.h2.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!barber.active)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.captionTextColor
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.l10n.dashboardBarberInactive,
                              style: context.appTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: context.appColors.captionTextColor,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                            locationName,
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
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: context.appColors.errorColor,
                  size: 22,
                ),
                onPressed: onDelete,
                tooltip: context.l10n.dashboardBarberDeleteButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarbersError extends StatelessWidget {
  const _BarbersError({
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
