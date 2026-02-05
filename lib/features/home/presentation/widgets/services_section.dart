import 'package:flutter/material.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

const _servicesSectionSpacing = 28.0;

/// Services list on home: shimmer when loading, list when loaded, nothing when empty.
/// Same pattern as [LocationsList] — one main widget + shimmer.
class ServicesSection extends ConsumerWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesForHomeProvider);

    return switch (servicesAsync) {
      AsyncLoading() => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ServicesSectionShimmer(),
          Gap(_servicesSectionSpacing),
        ],
      ),
      AsyncData(:final value) =>
        value.isEmpty
            ? const SizedBox.shrink()
            : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ServicesContent(
                  services: value,
                  title: context.l10n.sectionPopularServices,
                ),
                Gap(_servicesSectionSpacing),
              ],
            ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Horizontal list of service cards for quick-action booking.
class _ServicesContent extends StatelessWidget {
  const _ServicesContent({
    required this.services,
    this.title = 'Services',
  });

  final List<ServiceEntity> services;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(title: title),
        Gap(context.appSizes.paddingSmall),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(right: context.appSizes.paddingMedium),
            itemCount: services.length,
            separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
            itemBuilder: (context, index) {
              final service = services[index];
              return _ServiceCard(
                service: service,
                onTap:
                    () => _openBookingWithService(context, service.serviceId),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openBookingWithService(BuildContext context, String serviceId) {
    context.push('${AppRoute.booking.path}?serviceId=$serviceId');
  }
}

class _ServicesSectionShimmer extends StatelessWidget {
  const _ServicesSectionShimmer();

  @override
  Widget build(BuildContext context) {
    const cardWidth = 160.0;
    const cardHeight = 124.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(title: context.l10n.sectionPopularServices),
        Gap(context.appSizes.paddingSmall),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(right: context.appSizes.paddingMedium),
            itemCount: 3,
            separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
            itemBuilder:
                (_, __) => ShimmerWrapper(
                  child: Container(
                    width: cardWidth,
                    padding: EdgeInsets.all(context.appSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: context.appColors.menuBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerPlaceholder(
                          width: 100,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerPlaceholder(
                          width: 120,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerPlaceholder(
                          width: 80,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

const _cardRadius = 16.0;
const _cardWidth = 160.0;

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
  });

  final ServiceEntity service;
  final VoidCallback onTap;

  String _formatPrice(BuildContext context, num price) =>
      context.formatPriceWithCurrency(price);

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          width: _cardWidth,
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: context.appColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service.name,
                style: context.appTextStyles.h2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.primaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatPrice(context, service.price),
                    style: context.appTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.primaryColorOnDark,
                    ),
                  ),
                  Text(
                    _formatDuration(service.durationMinutes),
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: context.appColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              Gap(6),
              Row(
                children: [
                  Text(
                    context.l10n.book,
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: context.appColors.primaryColorOnDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: context.appColors.primaryColorOnDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
