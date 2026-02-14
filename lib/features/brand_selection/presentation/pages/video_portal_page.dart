import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/core/widgets/video_background.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/brand_selection/presentation/bloc/brand_onboarding_notifier.dart';
import 'package:barber/features/brand_selection/presentation/bloc/portal_notifier.dart';
import 'package:barber/features/home/di.dart';

/// Design constants
class _PortalDesign {
  static const neutralBackground = Color(0xFF020617);
  static const primaryIndigo = Color(0xFF6366F1);
  static const secondaryIndigo = Color(
    0xFF4338CA,
  ); // Deep sapphire for video grading
  static const morphDuration = Duration(
    milliseconds: 3000,
  ); // Extended for smooth settling
  static const scaleDuration = Duration(milliseconds: 1800);
  static const revealHoldDuration = Duration(milliseconds: 1500);
}

/// Monolith card design constants
class _MonolithDesign {
  static const double width = 280.0;
  static const double height = 360.0;
  static const double neutralRadius = 32.0;
  static const double morphedRadius = 24.0;
  static const double logoSize = 120.0;
  static const double blurSigma = 25.0; // Matching "Search by Tag" button
  static const double borderWidth = 1.5; // Precise border
}

/// Provider for brand onboarding
final _brandOnboardingNotifierProvider = StateNotifierProvider.autoDispose<
  BrandOnboardingNotifier,
  BaseState<BrandOnboardingState>
>((ref) {
  final brandRepo = ref.watch(brandRepositoryProvider);
  final userBrandsRepo = ref.watch(userBrandsRepositoryProvider);
  final guestStorage = ref.watch(guestStorageProvider);
  return BrandOnboardingNotifier(brandRepo, userBrandsRepo, guestStorage);
});

/// Cinematic Video Portal Page - Apple-grade premium glass effects
class VideoPortalPage extends HookConsumerWidget {
  const VideoPortalPage({
    super.key,
    this.initialOpenScanner = false,
  });

  /// When true, the scanner is shown immediately (e.g. when entering from QR in switcher).
  final bool initialOpenScanner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showScanner = useState(false);
    final showSearch = useState(false);

    // Open scanner on mount when entering via QR entry point
    useEffect(() {
      if (initialOpenScanner) {
        showScanner.value = true;
      }
      return null;
    }, [initialOpenScanner]);

    // Animation controllers
    final morphController = useAnimationController(
      duration: _PortalDesign.morphDuration,
    );
    final morphCurve = useMemoized(
      () => CurvedAnimation(
        parent: morphController,
        // easeOutQuart for smooth color settling into brand identity
        curve: Curves.easeOutQuart,
      ),
      [morphController],
    );
    final morphValue = useAnimation(morphCurve);

    final scaleController = useAnimationController(
      duration: _PortalDesign.scaleDuration,
    );
    final scaleCurve = useMemoized(
      () => TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0),
          weight: 60,
        ),
      ]).animate(
        CurvedAnimation(
          parent: scaleController,
          curve: Curves.easeInOut,
        ),
      ),
      [scaleController],
    );
    final scaleValue = useAnimation(scaleCurve);

    // Mounted state tracking
    final isMounted = useRef(true);
    useEffect(() {
      return () {
        isMounted.value = false;
      };
    }, []);

    // Portal state
    final portalState = ref.watch(portalNotifierProvider);
    final portalNotifier = ref.read(portalNotifierProvider.notifier);

    // Listen for brand selection
    ref.listen<BaseState<BrandOnboardingState>>(
      _brandOnboardingNotifierProvider,
      (prev, next) {
        debugPrint(
          '[VideoPortal] Listener triggered: state type=${next.runtimeType}',
        );
        if (next is BaseData<BrandOnboardingState>) {
          final state = next.data;
          debugPrint(
            '[VideoPortal] BaseData received: selectedBrand=${state.selectedBrand?.name}, error=${state.errorMessage}, isLoading=${state.isLoading}',
          );
          if (state.errorMessage != null) {
            showErrorSnackBar(context, message: state.errorMessage!);
          } else if (state.selectedBrand != null && !state.isLoading) {
            debugPrint('[VideoPortal] Brand selected, triggering morph');
            // Close scanner/search first to prevent user interaction
            showScanner.value = false;
            showSearch.value = false;

            // Trigger the morph animation sequence
            _triggerMorph(
              state.selectedBrand!,
              portalNotifier,
              morphController,
              scaleController,
              isMounted,
              ref,
              context,
            );
          }
        }
      },
    );

    // Reset on entry and set brand selection flow flag
    useEffect(() {
      portalNotifier.reset();
      // Set flag to prevent router redirects during animation
      // Use Future.microtask to defer provider modification until after build
      Future.microtask(() {
        ref.read(isInBrandSelectionFlowProvider.notifier).state = true;
        debugPrint('[VideoPortal] Brand selection flow flag SET');
      });
      return () {
        // Clear flag when leaving portal
        Future.microtask(() {
          ref.read(isInBrandSelectionFlowProvider.notifier).state = false;
          debugPrint('[VideoPortal] Brand selection flow flag CLEARED');
        });
      };
    }, []);

    // Calculate colors
    final targetColor =
        portalState.selectedBrand != null
            ? _hexToColor(portalState.selectedBrand!.primaryColor)
            : _PortalDesign.primaryIndigo;

    return PopScope(
      canPop: !showScanner.value && !showSearch.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (showScanner.value) {
          showScanner.value = false;
        } else if (showSearch.value) {
          showSearch.value = false;
          ref.read(_brandOnboardingNotifierProvider.notifier).clearSearch();
        }
      },
      child: Scaffold(
        backgroundColor: _PortalDesign.neutralBackground,
        resizeToAvoidBottomInset:
            false, // Prevent keyboard from pushing content
        body: Stack(
          children: [
            // Cinematic video background with color grading
            Positioned.fill(
              child: VideoBackground(
                targetColor: targetColor,
                morphProgress: morphValue,
                baseColor: _PortalDesign.secondaryIndigo,
                opacity: 0.65,
              ),
            ),

            // Main content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  showScanner.value
                      ? _ScannerView(
                        onClose: () => showScanner.value = false,
                      )
                      : showSearch.value
                      ? _SearchView(
                        onClose: () {
                          showSearch.value = false;
                          ref
                              .read(_brandOnboardingNotifierProvider.notifier)
                              .clearSearch();
                        },
                      )
                      : _PortalContent(
                        brand: portalState.selectedBrand,
                        morphProgress: morphValue,
                        scale: scaleValue,
                        canInteract: portalNotifier.canInteract,
                        onScanTap: () => showScanner.value = true,
                        onSearchTap: () => showSearch.value = true,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerMorph(
    BrandEntity brand,
    PortalNotifier portalNotifier,
    AnimationController morphController,
    AnimationController scaleController,
    ObjectRef<bool> isMounted,
    WidgetRef ref,
    BuildContext context,
  ) async {
    debugPrint('[VideoPortal] Starting morph for: ${brand.name}');
    portalNotifier.onBrandSelected(brand);

    await Future.wait([
      morphController.forward(),
      scaleController.forward(),
    ]);

    if (!isMounted.value) return;

    portalNotifier.onMorphComplete();
    debugPrint('[VideoPortal] Morph complete');

    // ignore: use_build_context_synchronously
    await _performCinematicReveal(
      brand,
      portalNotifier,
      isMounted,
      ref,
      context,
    );
  }

  Future<void> _performCinematicReveal(
    BrandEntity brand,
    PortalNotifier portalNotifier,
    ObjectRef<bool> isMounted,
    WidgetRef ref,
    BuildContext context,
  ) async {
    await Future.delayed(_PortalDesign.revealHoldDuration);

    if (!isMounted.value || !context.mounted) return;

    debugPrint('[VideoPortal] Starting hero transition');
    portalNotifier.onHeroTransitionStart();

    // Clear brand selection flow flag BEFORE locking brand
    // This allows router to redirect to home when brand is locked
    ref.read(isInBrandSelectionFlowProvider.notifier).state = false;
    debugPrint(
      '[VideoPortal] Brand selection flow flag cleared before navigation',
    );

    // Lock the brand before navigation
    ref.read(lockedBrandIdProvider.notifier).state = brand.brandId;
    debugPrint('[VideoPortal] Brand locked: ${brand.brandId}');

    // Small delay for state propagation
    await Future.delayed(const Duration(milliseconds: 100));

    if (!isMounted.value || !context.mounted) return;

    // Pause video before navigating (home will dispose it)
    debugPrint('[VideoPortal] Pausing video before navigating to home');
    ref.read(videoPreloaderServiceProvider).portalVideoController?.pause();

    // Invalidate providers to ensure they reload with new brand
    ref.invalidate(defaultBrandProvider);
    ref.invalidate(homeNotifierProvider);

    // Small delay to ensure invalidation completes
    await Future.delayed(const Duration(milliseconds: 50));

    if (!isMounted.value || !context.mounted) return;

    // ignore: use_build_context_synchronously
    context.go(AppRoute.home.path);
  }
}

/// Glass monolith card with premium glassmorphism
class _GlassMonolithCard extends HookWidget {
  const _GlassMonolithCard({
    required this.brand,
    required this.morphProgress,
    required this.scale,
  });

  final BrandEntity? brand;
  final double morphProgress;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Professional breathing animation - 3.5s cycle with sine curve
    final breatheController = useAnimationController(
      duration: const Duration(milliseconds: 3500),
    );

    // Smooth breathing curve (sine wave for natural feel)
    final breatheCurve = useMemoized(
      () => CurvedAnimation(
        parent: breatheController,
        curve: Curves.easeInOutSine,
      ),
      [breatheController],
    );

    // Start infinite breathing animation
    useEffect(() {
      breatheController.repeat(reverse: true);
      return null;
    }, [breatheController]);

    final breatheValue = useAnimation(breatheCurve);

    // Subtle scale: 1.0 to 1.015 (1.5% growth)
    final breatheScale = 1.0 + (breatheValue * 0.015);

    // Animate border radius
    final borderRadius =
        ui.lerpDouble(
          _MonolithDesign.neutralRadius,
          _MonolithDesign.morphedRadius,
          morphProgress,
        )!;

    // Parse brand color
    final brandColor =
        brand != null
            ? _hexToColor(brand!.primaryColor)
            : _PortalDesign.primaryIndigo;

    return Transform.scale(
      scale: scale * breatheScale, // Combine user scale with breathing
      child: SizedBox(
        width: _MonolithDesign.width,
        height: _MonolithDesign.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Depth shadows for floating effect (with breathing)
            Container(
              width: _MonolithDesign.width,
              height: _MonolithDesign.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color:
                        Color.lerp(
                          const Color(0x66000000),
                          const Color(0x80000000),
                          breatheValue * 0.3,
                        )!,
                    blurRadius: 30 + (breatheValue * 5),
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color:
                        Color.lerp(
                          const Color(0x33000000),
                          const Color(0x4D000000),
                          breatheValue * 0.3,
                        )!,
                    blurRadius: 60 + (breatheValue * 10),
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
            ),

            // Main glass monolith
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: _MonolithDesign.blurSigma,
                  sigmaY: _MonolithDesign.blurSigma,
                ),
                child: Container(
                  width: _MonolithDesign.width,
                  height: _MonolithDesign.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    // Fill with subtle white opacity
                    color: Colors.white.withValues(alpha: 0.08),
                    // Gradient border matching "Search by Tag" button
                    border: Border.all(
                      width: _MonolithDesign.borderWidth,
                      color: Colors.transparent,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _GradientBorderPainter(
                      borderRadius: borderRadius,
                      borderWidth: _MonolithDesign.borderWidth,
                      brandColor: brandColor,
                      morphProgress: morphProgress,
                      breatheIntensity: breatheValue,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing center effect (neutral state)
                        if (brand == null) const _PulsingCenter(),

                        // Brand content (logo or placeholder)
                        _BrandContent(
                          brand: brand,
                          morphProgress: morphProgress,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient border painter matching "Search by Tag" button style
class _GradientBorderPainter extends CustomPainter {
  const _GradientBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.brandColor,
    required this.morphProgress,
    required this.breatheIntensity,
  });

  final double borderRadius;
  final double borderWidth;
  final Color brandColor;
  final double morphProgress;
  final double breatheIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Border gradient: white 0.2 at top-left to transparent at bottom-right
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(
          const Color(0x33FFFFFF), // 0.2 alpha
          const Color(0x40FFFFFF),
          breatheIntensity * 0.3,
        )!,
        const Color(0x00FFFFFF), // transparent
      ],
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.brandColor != brandColor ||
        oldDelegate.breatheIntensity != breatheIntensity;
  }
}

/// Pulsing center effect for neutral state
class _PulsingCenter extends HookWidget {
  const _PulsingCenter();

  @override
  Widget build(BuildContext context) {
    // Smooth pulsing animation (4 second cycle for more subtle effect)
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 4000),
    );

    // Start the repeating animation (no reverse - restarts from beginning)
    useEffect(() {
      controller.repeat();
      return null;
    }, [controller]);

    final pulseValue = useAnimation(controller);

    return CustomPaint(
      painter: _CenterPulsePainter(
        pulseValue: pulseValue,
      ),
      size: const Size(_MonolithDesign.width, _MonolithDesign.height),
    );
  }
}

/// Painter for the center pulsing effect
class _CenterPulsePainter extends CustomPainter {
  const _CenterPulsePainter({
    required this.pulseValue,
  });

  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Three concentric rings pulsing outward only
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.2; // Stagger the rings
      final adjustedPulse = (pulseValue + delay) % 1.0;

      // Only draw if pulse has started
      if (adjustedPulse < 0.05) continue;

      // Radius grows from 50 to 120
      final radius = 50.0 + (adjustedPulse * 70.0);

      // Opacity: subtle fade
      final fadeOut = 1.0 - (adjustedPulse * adjustedPulse);
      final opacity = fadeOut * 0.08;

      // Only draw if visible
      if (opacity < 0.01) continue;

      final paint =
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CenterPulsePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

/// Brand content: logo or placeholder with smooth fade
class _BrandContent extends StatelessWidget {
  const _BrandContent({
    required this.brand,
    required this.morphProgress,
  });

  final BrandEntity? brand;
  final double morphProgress;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      opacity: brand != null ? morphProgress : 0.0,
      curve: Curves.easeOutExpo,
      child:
          brand != null
              ? _BrandLogo(
                logoUrl: brand!.logoUrl,
                brandName: brand!.name,
                morphProgress: morphProgress,
              )
              : const _PlaceholderIcon(),
    );
  }
}

/// Brand logo with scale animation
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({
    required this.logoUrl,
    required this.brandName,
    required this.morphProgress,
  });

  final String logoUrl;
  final String brandName;
  final double morphProgress;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8 + (morphProgress * 0.2),
      child: Container(
        width: _MonolithDesign.logoSize,
        height: _MonolithDesign.logoSize,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child:
              logoUrl.isNotEmpty
                  ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0x1AFFFFFF),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      );
                    },
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: const Color(0x1AFFFFFF),
                          child: const Icon(
                            Icons.store,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                  )
                  : Container(
                    color: const Color(0x1AFFFFFF),
                    child: const Icon(
                      Icons.store,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }
}

/// Placeholder icon for neutral state
class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.radio_button_unchecked,
      size: 80,
      color: Color(0x4DFFFFFF), // white 0.3
    );
  }
}

/// Portal content with glass monolith and clean buttons
class _PortalContent extends StatelessWidget {
  const _PortalContent({
    required this.brand,
    required this.morphProgress,
    required this.scale,
    required this.canInteract,
    required this.onScanTap,
    required this.onSearchTap,
  });

  final BrandEntity? brand;
  final double morphProgress;
  final double scale;
  final bool canInteract;
  final VoidCallback onScanTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    // Accent color for buttons
    final brandColor = brand != null ? _hexToColor(brand!.primaryColor) : null;
    final accentColor =
        Color.lerp(
          _PortalDesign.primaryIndigo,
          brandColor ?? _PortalDesign.primaryIndigo,
          morphProgress,
        )!;

    return Column(
      children: [
        const Spacer(),

        // Glass monolith card
        Hero(
          tag: 'brand-portal',
          child: _GlassMonolithCard(
            brand: brand,
            morphProgress: morphProgress,
            scale: scale,
          ),
        ),

        const Spacer(),

        // Clean buttons with inner glow
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: canInteract ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !canInteract,
            child: Padding(
              padding: EdgeInsets.all(context.appSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PremiumButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: context.l10n.scanQrCode,
                    onTap: onScanTap,
                    isPrimary: true,
                    accentColor: accentColor,
                  ),
                  Gap(context.appSizes.paddingMedium),
                  _PremiumButton(
                    icon: Icons.search_rounded,
                    label: context.l10n.searchByTag,
                    onTap: onSearchTap,
                    isPrimary: false,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),

        Gap(context.appSizes.paddingXxl),
      ],
    );
  }
}

/// Premium button with mechanical haptic feedback
class _PremiumButton extends HookWidget {
  const _PremiumButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    // Scale animation controller for mechanical feedback
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );

    final scaleValue = useAnimation(scaleController);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        scaleController.reverse();
      },
      onTapUp: (_) {
        scaleController.forward();
        onTap();
      },
      onTapCancel: () => scaleController.forward(),
      child: Transform.scale(
        scale: scaleValue,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.appSizes.paddingMedium,
            horizontal: context.appSizes.paddingLarge,
          ),
          decoration: BoxDecoration(
            color:
                isPrimary
                    ? accentColor.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
            border: Border.all(
              width: 1.0,
              color:
                  isPrimary
                      ? accentColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? accentColor : Colors.white,
                size: 22,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                label,
                style: context.appTextStyles.button.copyWith(
                  color: isPrimary ? accentColor : Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scanner view for QR code scanning
class _ScannerView extends HookConsumerWidget {
  const _ScannerView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(
      () => MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      ),
    );

    final isProcessing = useState(false);

    useEffect(() {
      return () => controller.dispose();
    }, []);

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) async {
            if (isProcessing.value) return;

            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;

            final raw = barcodes.first.rawValue?.trim();
            if (raw == null || raw.isEmpty) return;

            isProcessing.value = true;

            final userIdAsync = ref.read(currentUserIdProvider);
            final userId = userIdAsync.valueOrNull;
            final notifier = ref.read(
              _brandOnboardingNotifierProvider.notifier,
            );

            if (userId != null) {
              await notifier.handleQrCode(raw, userId);
            } else if (raw.startsWith('brand:')) {
              final brandId = raw.substring(6).trim();
              if (brandId.isNotEmpty) {
                await notifier.selectBrandForGuest(brandId);
              }
            }

            await Future.delayed(const Duration(seconds: 2));
            if (context.mounted) {
              isProcessing.value = false;
            }
          },
        ),

        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.appSizes.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassIconButton(
                  icon: Icons.close,
                  onPressed: onClose,
                ),
                _GlassIconButton(
                  icon: Icons.flash_on,
                  onPressed: () => controller.toggleTorch(),
                ),
              ],
            ),
          ),
        ),

        const _LoadingOverlay(),
      ],
    );
  }
}

/// Glass icon button for scanner controls
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/// Loading overlay for async operations
class _LoadingOverlay extends HookConsumerWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_brandOnboardingNotifierProvider);
    final isLoading =
        state is BaseData<BrandOnboardingState> && state.data.isLoading;

    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

/// Search view for tag-based brand search
class _SearchView extends HookConsumerWidget {
  const _SearchView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final state = ref.watch(_brandOnboardingNotifierProvider);
    final data = state is BaseData<BrandOnboardingState> ? state.data : null;
    final isLoading = data?.isLoading ?? false;
    final searchResult = data?.searchResult;

    return Column(
      children: [
        const Gap(24),
        Padding(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back,
                onPressed: onClose,
              ),
              Gap(context.appSizes.paddingSmall),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: context.appTextStyles.body.copyWith(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'brand-tag',
                      hintStyle: context.appTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      prefixText: '@',
                      prefixStyle: context.appTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        ref
                            .read(_brandOnboardingNotifierProvider.notifier)
                            .searchByTag(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        if (isLoading)
          LinearProgressIndicator(
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.all(context.appSizes.paddingLarge),
            child:
                searchResult != null
                    ? _BrandResultCard(brand: searchResult)
                    : data?.errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          Gap(context.appSizes.paddingMedium),
                          Text(
                            data?.errorMessage ?? '',
                            style: context.appTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : Center(
                      child: Text(
                        context.l10n.searchBusinessByTag,
                        style: context.appTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}

/// Brand result card for search results
class _BrandResultCard extends ConsumerWidget {
  const _BrandResultCard({required this.brand});

  final BrandEntity brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
            image:
                brand.logoUrl.isNotEmpty
                    ? DecorationImage(
                      image: NetworkImage(brand.logoUrl),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              brand.logoUrl.isEmpty
                  ? Icon(
                    Icons.store,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.5),
                  )
                  : null,
        ),
        Gap(context.appSizes.paddingLarge),
        Text(
          brand.name,
          style: context.appTextStyles.h2.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        if (brand.tag != null) ...[
          Gap(context.appSizes.paddingSmall),
          Text(
            '@${brand.tag}',
            style: context.appTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        Gap(context.appSizes.paddingXxl),
        SizedBox(
          width: double.infinity,
          child: _PremiumButton(
            icon: Icons.check_circle,
            label: 'Join ${brand.name}',
            onTap: () {
              final currentUserId = ref.read(currentUserIdProvider).valueOrNull;
              final notifier = ref.read(
                _brandOnboardingNotifierProvider.notifier,
              );
              if (currentUserId == null || currentUserId.isEmpty) {
                notifier.selectBrandForGuest(brand.brandId);
              } else {
                notifier.joinBrand(brand.brandId, currentUserId);
              }
            },
            isPrimary: true,
            accentColor: _hexToColor(brand.primaryColor),
          ),
        ),
      ],
    );
  }
}

/// Utility function to parse hex color
Color _hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  if (hexCode.length == 6) {
    return Color(int.parse('FF$hexCode', radix: 16));
  }
  return _PortalDesign.primaryIndigo;
}
