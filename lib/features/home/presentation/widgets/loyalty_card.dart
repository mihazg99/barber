import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/brand/di.dart' as brand_di;
import 'package:barber/features/home/di.dart';
import 'package:barber/core/di.dart';

const _sectionSpacing = 28.0;

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

void _playPointsAwardedHaptic() {
  // Chaotic haptic pattern like Apple Pay
  HapticFeedback.mediumImpact();
  Future.delayed(const Duration(milliseconds: 80), () {
    HapticFeedback.lightImpact();
  });
  Future.delayed(const Duration(milliseconds: 140), () {
    HapticFeedback.lightImpact();
  });
  Future.delayed(const Duration(milliseconds: 220), () {
    HapticFeedback.mediumImpact();
  });
  Future.delayed(const Duration(milliseconds: 280), () {
    HapticFeedback.lightImpact();
  });
  Future.delayed(const Duration(milliseconds: 360), () {
    HapticFeedback.heavyImpact();
  });
}

/// Loyalty block on home: shimmer when loading, flipping card when user is present.
class LoyaltyCard extends HookConsumerWidget {
  const LoyaltyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return switch (currentUserAsync) {
      AsyncLoading() => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
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

/// Flipping loyalty card: front = points/chip/name/CTA, back = big QR. Tap to flip.
class _LoyaltyCardContent extends HookConsumerWidget {
  const _LoyaltyCardContent({required this.user});

  final UserEntity user;

  static const _cardHeight = 156.0;
  static const _flipDuration = Duration(milliseconds: 400);
  static const _pointsRollDuration = Duration(milliseconds: 1500);
  static const _backQrSize = 120.0;
  static const _flipToBackDelay = Duration(milliseconds: 100);
  static const _flipToFrontDelay = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    // Brand gradient: primary → secondary (e.g. green→darker green for Nomad)
    final gradientStart = c.primaryColor;
    final gradientEnd = c.secondaryColor;
    final accent = c.primaryColor;

    final cardState = ref.watch(loyaltyCardNotifierProvider);
    final notifier = ref.read(loyaltyCardNotifierProvider.notifier);

    final flipController = useAnimationController(duration: _flipDuration);
    final flipCurve = useMemoized(
      () => CurvedAnimation(
        parent: flipController,
        curve: Curves.easeInOut,
      ),
      [flipController],
    );
    useAnimation(flipCurve);

    final previousPoints = useRef<int>(user.loyaltyPoints);
    final pointsController = useAnimationController(
      duration: _pointsRollDuration,
    );
    final pointsCurve = useMemoized(
      () => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: pointsController, curve: Curves.easeOut),
      ),
      [pointsController],
    );
    useAnimation(pointsCurve);
    final rollStart = useRef<int>(user.loyaltyPoints);
    final rollEnd = useRef<int>(user.loyaltyPoints);

    // Scale animation for points display during counting
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    final scaleCurve = useMemoized(
      () => Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(
          parent: scaleController,
          curve: Curves.easeInOut,
        ),
      ),
      [scaleController],
    );
    useAnimation(scaleCurve);

    useEffect(() {
      if (user.loyaltyPoints > previousPoints.value) {
        final pointsAdded = user.loyaltyPoints - previousPoints.value;
        _log.d(
          'LoyaltyCard: Points increased from ${previousPoints.value} to ${user.loyaltyPoints} (+$pointsAdded)',
        );
        rollStart.value = previousPoints.value;
        rollEnd.value = user.loyaltyPoints;

        // Multi-stage animation sequence
        Future(() async {
          // Stage 1: Flip to back (showing QR being scanned)
          _log.d('LoyaltyCard: Stage 1 - Flip to back');
          notifier.flipToBack();
          await Future.delayed(_flipToBackDelay);

          // Stage 2: Start haptic feedback
          _log.d('LoyaltyCard: Stage 2 - Haptic feedback');
          _playPointsAwardedHaptic();
          await Future.delayed(_flipToFrontDelay);

          // Stage 3: Flip to front and start counting animation
          _log.d('LoyaltyCard: Stage 3 - Flip to front and count');
          notifier.flipToFront();
          await Future.delayed(const Duration(milliseconds: 200));

          // Stage 4: Animate points counting with scale
          _log.d('LoyaltyCard: Stage 4 - Animate counting');
          scaleController.forward().then((_) => scaleController.reverse());
          await pointsController.forward();

          previousPoints.value = user.loyaltyPoints;
          pointsController.reset();
          _log.d('LoyaltyCard: Animation complete');
        });
      } else if (!pointsController.isAnimating) {
        previousPoints.value = user.loyaltyPoints;
      }
      return null;
    }, [user.loyaltyPoints]);

    useEffect(() {
      if (cardState.isFlipped &&
          flipController.status != AnimationStatus.completed) {
        flipController.forward();
      } else if (!cardState.isFlipped &&
          flipController.status != AnimationStatus.dismissed) {
        flipController.reverse();
      }
      return null;
    }, [cardState.isFlipped]);

    final displayedPoints =
        pointsController.isAnimating
            ? (rollStart.value +
                    (rollEnd.value - rollStart.value) * pointsCurve.value)
                .round()
            : user.loyaltyPoints;

    final brandName =
        ref.watch(brand_di.headerBrandNameProvider).valueOrNull ??
        ref.watch(flavorConfigProvider).values.brandConfig.appTitle;

    void onCardTap() {
      if (flipController.isAnimating || pointsController.isAnimating) return;
      notifier.flip();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onCardTap,
        child: SizedBox(
          height: _cardHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _LoyaltyCardBackFace(
                  userId: user.userId,
                  qrSize: _backQrSize,
                  flipT: flipCurve.value,
                  gradientStart: gradientStart,
                  gradientEnd: gradientEnd,
                  accent: accent,
                  colors: c,
                  brandName: brandName,
                ),
              ),
              Positioned.fill(
                child: _LoyaltyCardFrontFace(
                  user: user,
                  displayedPoints: displayedPoints,
                  gradientStart: gradientStart,
                  gradientEnd: gradientEnd,
                  accent: accent,
                  flipT: flipCurve.value,
                  onQrTap: onCardTap,
                  pointsScale: scaleCurve.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Front of the card: points, chip, title, name, CTA, small tappable QR (tap QR to flip).
class _LoyaltyCardFrontFace extends HookWidget {
  const _LoyaltyCardFrontFace({
    required this.user,
    required this.displayedPoints,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.flipT,
    required this.onQrTap,
    required this.pointsScale,
  });

  final UserEntity user;
  final int displayedPoints;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final double flipT;
  final VoidCallback onQrTap;
  final double pointsScale;

  static const _chipSize = 36.0;
  // Kingsman-style golden chip (from default.json: primary #9B784A, secondary #1A1614)
  static const _chipGoldTop = Color(0xFF9B784A);
  static const _chipGoldBottom = Color(0xFFB8956A);
  static const _chipGoldBorder = Color(0xFF7A6039);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const cardRadius = 16.0;

    final angle = flipT * math.pi;
    final visible = flipT < 0.5;

    return IgnorePointer(
      ignoring: !visible,
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
          child: Material(
            color: Colors.transparent,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: _chipSize,
                          height: _chipSize * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [
                                _chipGoldTop,
                                _chipGoldBottom,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: _chipGoldBorder,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.scale(
                          scale: pointsScale,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$displayedPoints ${context.l10n.loyaltyPointsAbbrev}',
                            style: context.appTextStyles.h2.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: c.primaryTextColor,
                              height: 1.1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        _SmallTappableQr(
                          userId: user.userId,
                          colors: c,
                          onTap: onQrTap,
                        ),
                      ],
                    ),
                    const Gap(10),
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
                              color: c.secondaryTextColor.withValues(
                                alpha: 0.95,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoute.loyalty.path),
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.loyaltyViewRewards,
                                style: context.appTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 9,
                                color: accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small QR on the front of the card. Tappable to start flip to big QR on the back.
class _SmallTappableQr extends StatelessWidget {
  const _SmallTappableQr({
    required this.userId,
    required this.colors,
    required this.onTap,
  });

  final String userId;
  final AppColors colors;
  final VoidCallback onTap;

  static const _qrSize = 26.0;
  static const _qrPadding = 5.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(_qrPadding),
        decoration: BoxDecoration(
          color: colors.primaryWhiteColor,
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
          data: userId,
          version: QrVersions.auto,
          size: _qrSize,
          backgroundColor: colors.primaryWhiteColor,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
          gapless: true,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Back of the card: centered QR and brand name at bottom right.
class _LoyaltyCardBackFace extends HookWidget {
  const _LoyaltyCardBackFace({
    required this.userId,
    required this.qrSize,
    required this.flipT,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.colors,
    this.brandName,
  });

  final String userId;
  final double qrSize;
  final double flipT;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final AppColors colors;
  final String? brandName;

  @override
  Widget build(BuildContext context) {
    const cardRadius = 16.0;

    final angle = math.pi + flipT * math.pi;
    final visible = flipT > 0.5;
    final styles = context.appTextStyles;

    return IgnorePointer(
      ignoring: !visible,
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
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
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primaryWhiteColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: userId,
                        version: QrVersions.auto,
                        size: qrSize * 0.576,
                        backgroundColor: colors.primaryWhiteColor,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                        gapless: true,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const Gap(14),
                    Text(
                      brandName?.trim().isNotEmpty == true
                          ? '${brandName!.trim()} Club'.toUpperCase()
                          : '',
                      style: styles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                        color: colors.captionTextColor.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                  width: 31,
                  height: 31,
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
