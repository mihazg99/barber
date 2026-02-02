import 'package:flutter/material.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:gap/gap.dart';

class BookingBarberSection extends StatelessWidget {
  const BookingBarberSection({
    super.key,
    required this.barbers,
    required this.selectedBarberId,
    required this.isAnyBarber,
    required this.onBarberSelected,
    required this.onAnyBarberSelected,
  });

  final List<BarberEntity> barbers;
  final String? selectedBarberId;
  final bool isAnyBarber;
  final void Function(BarberEntity) onBarberSelected;
  final VoidCallback onAnyBarberSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
          child: Text(
            'Select Barber',
            style: context.appTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.primaryTextColor,
            ),
          ),
        ),
        Gap(context.appSizes.paddingSmall),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
            itemCount: barbers.length + 1, // +1 for "Any Barber"
            separatorBuilder: (_, __) => Gap(context.appSizes.paddingMedium),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AnyBarberCard(
                  isSelected: isAnyBarber,
                  onTap: onAnyBarberSelected,
                );
              }
              final barber = barbers[index - 1];
              final isSelected = barber.barberId == selectedBarberId;
              return _BarberCircle(
                barber: barber,
                isSelected: isSelected,
                onTap: () => onBarberSelected(barber),
              );
            },
          ),
        ),
      ],
    );
  }
}

const _circleSize = 72.0;

class _AnyBarberCard extends StatelessWidget {
  const _AnyBarberCard({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                color: isSelected
                    ? context.appColors.primaryColor
                    : context.appColors.menuBackgroundColor,
                border: Border.all(
                  color: isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.primaryTextColor.withValues(alpha: 0.12),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.people_outline,
                  size: 32,
                  color: isSelected
                      ? context.appColors.primaryWhiteColor
                      : context.appColors.primaryColor,
                ),
              ),
            ),
            Gap(8),
            SizedBox(
              width: _circleSize + 24,
              child: Text(
                'Any Barber',
                style: context.appTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Gap(2),
            Text(
              isSelected ? 'Selected' : 'Select',
              style: context.appTextStyles.caption.copyWith(
                fontSize: 11,
                color: isSelected
                    ? context.appColors.primaryColor
                    : context.appColors.captionTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarberCircle extends StatelessWidget {
  const _BarberCircle({
    required this.barber,
    required this.isSelected,
    required this.onTap,
  });

  final BarberEntity barber;
  final bool isSelected;
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
                  color: isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.primaryTextColor.withValues(alpha: 0.12),
                  width: isSelected ? 3 : 1,
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
                  color: isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Gap(2),
            Text(
              isSelected ? 'Selected' : 'Select',
              style: context.appTextStyles.caption.copyWith(
                fontSize: 11,
                color: isSelected
                    ? context.appColors.primaryColor
                    : context.appColors.captionTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
