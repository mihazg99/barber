import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

/// Horizontal list of service cards for quick-action booking.
class ServicesSection extends StatelessWidget {
  const ServicesSection({
    super.key,
    required this.services,
    this.title = 'Services',
  });

  final List<ServiceEntity> services;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

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
                onTap: () => _openBookingWithService(context, service.serviceId),
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

const _cardRadius = 16.0;
const _cardWidth = 160.0;

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
  });

  final ServiceEntity service;
  final VoidCallback onTap;

  static String _formatPrice(num price) {
    if (price == price.toInt()) return '\$${price.toInt()}';
    return '\$${price.toStringAsFixed(2)}';
  }

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
            boxShadow: [
              BoxShadow(
                color: context.appColors.primaryTextColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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
                    _formatPrice(service.price),
                    style: context.appTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.primaryColor,
                    ),
                  ),
                  Text(
                    _formatDuration(service.durationMinutes),
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: context.appColors.captionTextColor,
                    ),
                  ),
                ],
              ),
              Gap(6),
              Row(
                children: [
                  Text(
                    'Book',
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: context.appColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    ),
                  Gap(4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: context.appColors.primaryColor,
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
