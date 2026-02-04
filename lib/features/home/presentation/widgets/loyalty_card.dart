import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _LoyaltyCardShimmer(),
          ),
          Gap(_sectionSpacing),
        ],
      ),
      AsyncData(:final value) =>
        value == null
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

/// Premium loyalty card styled like Amex/Diners: dark gradient, gold accents, credit-card layout.
class _LoyaltyCardContent extends StatelessWidget {
  const _LoyaltyCardContent({required this.user});

  final UserEntity user;

  static const _cardRadius = 16.0;
  static const _cardHeight = 156.0;
  static const _qrSize = 52.0;
  static const _qrPadding = 5.0;
  static const _chipSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const darkStart = Color(0xFF1A1614);
    const darkEnd = Color(0xFF0D0B0A);
    final gold = c.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: () => context.push(AppRoute.loyalty.path),
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Container(
            height: _cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_cardRadius),
              gradient: const LinearGradient(
                colors: [darkStart, darkEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Top row: chip (left) + LOYALTY (right) — like real card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: _chipSize,
                        height: _chipSize * 0.75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              gold.withValues(alpha: 0.4),
                              gold.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      Text(
                        context.l10n.loyaltyTitle,
                        style: context.appTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                          color: c.captionTextColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  /// Middle row: points (left, card-number position) + QR (right, scan zone)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${user.loyaltyPoints} pts',
                        style: context.appTextStyles.h2.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: c.primaryTextColor,
                          height: 1.1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(_qrPadding),
                        decoration: BoxDecoration(
                          color: c.primaryWhiteColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: user.userId,
                          version: QrVersions.auto,
                          size: _qrSize,
                          backgroundColor: c.primaryWhiteColor,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: c.secondaryColor,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: c.secondaryColor,
                          ),
                          gapless: true,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),

                  /// Bottom row: cardholder name (left) + view rewards (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName.trim().isEmpty
                              ? context.l10n.loyaltyMember
                              : user.fullName.toUpperCase(),
                          style: context.appTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: c.secondaryTextColor.withValues(alpha: 0.95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.loyaltyViewRewards,
                            style: context.appTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(4),
                          Icon(Icons.arrow_forward_ios, size: 9, color: gold),
                        ],
                      ),
                    ],
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

class _LoyaltyCardShimmer extends StatelessWidget {
  const _LoyaltyCardShimmer();

  static const _cardRadius = 16.0;
  static const _cardHeight = 156.0;

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        height: _cardHeight,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: context.appColors.menuBackgroundColor,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(
                  width: 36,
                  height: 27,
                  borderRadius: BorderRadius.circular(6),
                ),
                ShimmerPlaceholder(
                  width: 60,
                  height: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerPlaceholder(
                  width: 90,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
                ShimmerPlaceholder(
                  width: 62,
                  height: 62,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerPlaceholder(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                ShimmerPlaceholder(
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
