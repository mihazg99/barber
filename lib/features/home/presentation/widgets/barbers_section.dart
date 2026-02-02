import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';

/// Horizontal list of barber circles for quick-action booking.
class BarbersSection extends StatelessWidget {
  const BarbersSection({
    super.key,
    required this.barbers,
    this.title = 'Your barbers',
  });

  final List<BarberEntity> barbers;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (barbers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(title: title),
        Gap(context.appSizes.paddingSmall),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(right: context.appSizes.paddingMedium),
            itemCount: barbers.length,
            separatorBuilder: (_, __) => Gap(context.appSizes.paddingMedium),
            itemBuilder: (context, index) {
              final barber = barbers[index];
              return _BarberCircle(
                barber: barber,
                onTap: () => _openBookingWithBarber(context, barber.barberId),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openBookingWithBarber(BuildContext context, String barberId) {
    context.push('${AppRoute.booking.path}?barberId=$barberId');
  }
}

const _circleSize = 72.0;

class _BarberCircle extends StatelessWidget {
  const _BarberCircle({
    required this.barber,
    required this.onTap,
  });

  final BarberEntity barber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = barber.name.isNotEmpty
        ? barber.name.trim().substring(0, 1).toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_circleSize / 2 + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _circleSize + 8,
              height: _circleSize + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.appColors.primaryTextColor.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Center(
                child: ClipOval(
                  child: barber.photoUrl.isEmpty
                      ? _AvatarPlaceholder(
                          initial: initial,
                          size: _circleSize,
                        )
                      : Image.network(
                          barber.photoUrl,
                          width: _circleSize,
                          height: _circleSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _AvatarPlaceholder(
                            initial: initial,
                            size: _circleSize,
                          ),
                        ),
                ),
              ),
            ),
            Gap(8),
            SizedBox(
              width: _circleSize + 24,
              child: Text(
                barber.name,
                style: context.appTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Gap(2),
            Text(
              'Book',
              style: context.appTextStyles.caption.copyWith(
                fontSize: 11,
                color: context.appColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({
    required this.initial,
    required this.size,
  });

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: context.appTextStyles.h1.copyWith(
          fontSize: 24,
          color: context.appColors.primaryColor,
        ),
      ),
    );
  }
}
