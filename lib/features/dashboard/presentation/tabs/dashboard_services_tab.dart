import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/gen/l10n/app_localizations.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

/// Superadmin services tab.
class DashboardServicesTab extends HookConsumerWidget {
  const DashboardServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardServicesNotifierProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          switch (state) {
            BaseInitial() => const _ServicesShimmer(),
            BaseLoading() => const _ServicesShimmer(),
            BaseData(:final data) => _ServicesList(
              services: data,
              onAdd: () => context.push(AppRoute.dashboardServiceForm.path),
              onEdit:
                  (s) => context.push(
                    AppRoute.dashboardServiceForm.path,
                    extra: s,
                  ),
              onDelete: (s) => _confirmDelete(context, ref, s),
            ),
            BaseError(:final message) => _ServicesError(
              message: message,
              onRetry:
                  () =>
                      ref
                          .read(dashboardServicesNotifierProvider.notifier)
                          .load(),
            ),
          },
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoute.dashboardServiceForm.path),
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
    ServiceEntity service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.l10n.dashboardServiceDeleteConfirm),
            content: Text(context.l10n.dashboardServiceDeleteConfirmMessage),
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
                child: Text(context.l10n.dashboardServiceDeleteButton),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(dashboardServicesNotifierProvider.notifier)
          .delete(service.serviceId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardServiceDeleted),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
      }
    }
  }
}

class _ServicesShimmer extends StatelessWidget {
  const _ServicesShimmer();

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
              height: 72,
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
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const Spacer(),
                  ShimmerPlaceholder(
                    width: 60,
                    height: 14,
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

class _ServicesList extends StatelessWidget {
  const _ServicesList({
    required this.services,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ServiceEntity> services;
  final VoidCallback onAdd;
  final void Function(ServiceEntity) onEdit;
  final void Function(ServiceEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.content_cut_outlined,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.dashboardServiceEmpty,
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
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceCard(
          service: service,
          onTap: () => onEdit(service),
          onDelete: () => onDelete(service),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.onDelete,
  });

  final ServiceEntity service;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static String _formatDuration(AppLocalizations l10n, int minutes) {
    if (minutes < 60) return l10n.durationMinutesShort(minutes);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return l10n.durationHoursShort(h);
    return l10n.durationHoursMinutesShort(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final availabilityLabel =
        service.availableAtLocations.isEmpty
            ? context.l10n.dashboardServiceAvailableAtAll
            : '${context.l10n.dashboardServiceAvailableAtSelected} (${service.availableAtLocations.length})';

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
                      service.name,
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.primaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4),
                    Text(
                      availabilityLabel,
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                    Gap(2),
                    Row(
                      children: [
                        Text(
                          context.formatPriceWithCurrency(service.price),
                          style: context.appTextStyles.h2.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(
                            context.l10n,
                            service.durationMinutes,
                          ),
                          style: context.appTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: context.appColors.captionTextColor,
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
                tooltip: context.l10n.dashboardServiceDeleteButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesError extends StatelessWidget {
  const _ServicesError({
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
