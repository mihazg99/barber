import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

const _cardWidth = 160.0;
const _cardRadius = 20.0;

/// Clean service card matching location card design aesthetic
/// Never use function widgets - this is a private widget class
class PremiumServiceCard extends HookWidget {
  const PremiumServiceCard({
    required this.service,
    required this.onTap,
    super.key,
  });

  final ServiceEntity service;
  final VoidCallback onTap;

  String _formatDuration(BuildContext context, int minutes) {
    if (minutes < 60) return context.l10n.durationMinutes(minutes);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return context.l10n.durationHours(h);
    return context.l10n.durationHoursMinutes(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          width: _cardWidth,
          decoration: BoxDecoration(
            color: c.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: c.borderColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Service name - flexible to handle long names
              Flexible(
                child: Text(
                  service.name,
                  style: context.appTextStyles.h2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.primaryTextColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Gap(8),

              // Duration with icon
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: c.captionTextColor,
                  ),
                  const Gap(4),
                  Text(
                    _formatDuration(context, service.durationMinutes),
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: c.captionTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Price and arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Price
                  Text(
                    context.formatPriceWithCurrency(service.price),
                    style: context.appTextStyles.h2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.primaryColor,
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: c.primaryColor,
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
