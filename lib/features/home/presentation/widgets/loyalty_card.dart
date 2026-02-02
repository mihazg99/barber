import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';

const _sectionSpacing = 28.0;

/// Loyalty block on home: shows shimmer when loading, card when user is present, nothing otherwise.
/// Same pattern as [LocationsList] — one main widget + shimmer.
class LoyaltyCard extends ConsumerWidget {
  const LoyaltyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return switch (currentUserAsync) {
      AsyncLoading() => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LoyaltyCardShimmer(),
            Gap(_sectionSpacing),
          ],
        ),
      AsyncData(:final value) => value == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LoyaltyCardContent(user: value),
                Gap(_sectionSpacing),
              ],
            ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Premium loyalty card with large, scannable QR for barbers + points and rewards entry.
class _LoyaltyCardContent extends StatelessWidget {
  const _LoyaltyCardContent({required this.user});

  final UserEntity user;

  static const _cardRadius = 20.0;
  /// QR size: scannable at counter without dominating the card.
  static const _qrSize = 80.0;
  /// Quiet zone (padding) around QR improves scanner detection.
  static const _qrPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoute.loyalty.path),
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color: context.appColors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.appColors.primaryTextColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Scan zone: high-contrast QR on pure white for reliability.
              Container(
                padding: const EdgeInsets.all(_qrPadding),
                decoration: BoxDecoration(
                  color: context.appColors.primaryWhiteColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.primaryTextColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: user.userId,
                  version: QrVersions.auto,
                  size: _qrSize,
                  backgroundColor: context.appColors.primaryWhiteColor,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: context.appColors.secondaryColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: context.appColors.secondaryColor,
                  ),
                  gapless: true,
                  padding: EdgeInsets.zero,
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loyalty card',
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                    Gap(6),
                    Text(
                      '${user.loyaltyPoints} points',
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.primaryTextColor,
                        height: 1.2,
                      ),
                    ),
                    Gap(6),
                    Row(
                      children: [
                        Text(
                          'View rewards',
                          style: context.appTextStyles.caption.copyWith(
                            fontSize: 14,
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
                    Gap(4),
                    Text(
                      'Show QR at counter',
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltyCardShimmer extends StatelessWidget {
  const _LoyaltyCardShimmer();

  @override
  Widget build(BuildContext context) {
    const cardRadius = 20.0;
    const qrSize = 96.0;
    return ShimmerWrapper(
      child: Container(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        decoration: BoxDecoration(
          color: context.appColors.menuBackgroundColor,
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShimmerPlaceholder(
              width: qrSize,
              height: qrSize,
              borderRadius: BorderRadius.circular(12),
            ),
            Gap(context.appSizes.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerPlaceholder(
                    width: 70,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  Gap(6),
                  ShimmerPlaceholder(
                    width: 90,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  Gap(6),
                  ShimmerPlaceholder(
                    width: 80,
                    height: 14,
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
