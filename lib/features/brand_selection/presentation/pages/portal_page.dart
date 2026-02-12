import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/brand_selection/presentation/bloc/brand_onboarding_notifier.dart';
import 'package:barber/features/brand_selection/presentation/bloc/portal_notifier.dart';
import 'package:barber/features/brand_selection/presentation/widgets/monolith_card.dart';
import 'package:barber/features/brand_selection/presentation/widgets/portal_background.dart';
import 'package:barber/features/home/di.dart';

/// Design constants for the Sapphire Architect style
class _PortalDesign {
  // Neutral state colors
  static const neutralBackground = Color(0xFF0F172A); // Deep Sapphire

  // Animation timings (120Hz optimized)
  static const morphDuration = Duration(milliseconds: 2500);
  static const scaleDuration = Duration(milliseconds: 1800);
  static const ambientLoopDuration = Duration(seconds: 10);
  static const revealHoldDuration = Duration(milliseconds: 1500);
}

/// Provider for portal state management
final _portalNotifierProvider =
    StateNotifierProvider.autoDispose<PortalNotifier, PortalState>((ref) {
  return PortalNotifier();
});

/// Provider for brand onboarding (reused from existing implementation)
final _brandOnboardingNotifierProvider = StateNotifierProvider.autoDispose<
    BrandOnboardingNotifier,
    BaseState<BrandOnboardingState>>((ref) {
  final brandRepo = ref.watch(brandRepositoryProvider);
  final userBrandsRepo = ref.watch(userBrandsRepositoryProvider);
  final guestStorage = ref.watch(guestStorageProvider);
  return BrandOnboardingNotifier(brandRepo, userBrandsRepo, guestStorage);
});

/// Main Portal Page with Morphing Monolith experience
class PortalPage extends HookConsumerWidget {
  const PortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showScanner = useState(false);
    final showSearch = useState(false);

    // Animation controllers
    final morphController = useAnimationController(
      duration: _PortalDesign.morphDuration,
    );
    final morphCurve = useMemoized(
      () => CurvedAnimation(
        parent: morphController,
        curve: Curves.easeInOutCubic,
      ),
      [morphController],
    );
    final morphValue = useAnimation(morphCurve);

    // Card scale animation (bounce effect)
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

    // Ambient background animation (continuous loop)
    final ambientController = useAnimationController(
      duration: _PortalDesign.ambientLoopDuration,
    )..repeat();
    final ambientValue = useAnimation(ambientController);

    // Track mounted state for async operations
    final isMounted = useRef(true);
    useEffect(() {
      return () {
        isMounted.value = false;
      };
    }, []);

    // Portal state
    final portalState = ref.watch(_portalNotifierProvider);
    final portalNotifier = ref.read(_portalNotifierProvider.notifier);

    // Listen for brand selection success
    ref.listen<BaseState<BrandOnboardingState>>(
      _brandOnboardingNotifierProvider,
      (prev, next) {
        debugPrint('[Portal] Listener triggered: state type=${next.runtimeType}');
        if (next is BaseData<BrandOnboardingState>) {
          final state = next.data;
          debugPrint('[Portal] BaseData received: selectedBrand=${state.selectedBrand?.name}, error=${state.errorMessage}, isLoading=${state.isLoading}');
          if (state.errorMessage != null) {
            showErrorSnackBar(context, message: state.errorMessage!);
          } else if (state.selectedBrand != null && !state.isLoading) {
            debugPrint('[Portal] Brand selected, triggering morph');
            // Close scanner/search first to prevent user interaction
            showScanner.value = false;
            showSearch.value = false;
            
            // Trigger morphing animation
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

    // Reset portal when entering page
    useEffect(() {
      portalNotifier.reset();
      return null;
    }, []);

    // Parse brand color if available
    final targetColor = portalState.selectedBrand != null
        ? _hexToColor(portalState.selectedBrand!.primaryColor)
        : _PortalDesign.neutralBackground;

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
        body: Stack(
          children: [
            // Animated background
            Positioned.fill(
              child: PortalBackground(
                baseColor: _PortalDesign.neutralBackground,
                targetColor: targetColor,
                morphProgress: morphValue,
                time: ambientValue * 2 * math.pi,
              ),
            ),

            // Main content
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showScanner.value
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
            ),
          ],
        ),
      ),
    );
  }

  /// Trigger morphing animation sequence
  Future<void> _triggerMorph(
    BrandEntity brand,
    PortalNotifier portalNotifier,
    AnimationController morphController,
    AnimationController scaleController,
    ObjectRef<bool> isMounted,
    WidgetRef ref,
    BuildContext context,
  ) async {
    debugPrint('[Portal] Starting morph for: ${brand.name}');
    portalNotifier.onBrandSelected(brand);

    // Run animations in parallel
    await Future.wait([
      morphController.forward(),
      scaleController.forward(),
    ]);

    if (!isMounted.value) return;

    portalNotifier.onMorphComplete();
    debugPrint('[Portal] Morph complete');

    // Cinematic reveal sequence
    // ignore: use_build_context_synchronously
    await _performCinematicReveal(
      brand,
      portalNotifier,
      isMounted,
      ref,
      context,
    );
  }

  /// Cinematic reveal: hold branded state, then navigate with hero
  Future<void> _performCinematicReveal(
    BrandEntity brand,
    PortalNotifier portalNotifier,
    ObjectRef<bool> isMounted,
    WidgetRef ref,
    BuildContext context,
  ) async {
    // Phase 1: Hold branded state
    await Future.delayed(_PortalDesign.revealHoldDuration);

    if (!isMounted.value || !context.mounted) return;

    debugPrint('[Portal] Starting hero transition');
    portalNotifier.onHeroTransitionStart();

    // Lock the brand before navigation
    ref.read(lockedBrandIdProvider.notifier).state = brand.brandId;
    debugPrint('[Portal] Brand locked: ${brand.brandId}');

    // Small delay for state propagation
    await Future.delayed(const Duration(milliseconds: 100));

    if (!isMounted.value || !context.mounted) return;

    // Invalidate providers to ensure they reload with new brand
    ref.invalidate(defaultBrandProvider);
    ref.invalidate(homeNotifierProvider);

    // Small delay to ensure invalidation completes
    await Future.delayed(const Duration(milliseconds: 50));

    if (!isMounted.value || !context.mounted) return;

    // Navigate with hero animation
    context.go(AppRoute.home.path);
  }

  /// Parse hex color string to Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return _PortalDesign.neutralBackground;
  }
}

/// Portal content with monolith card and action buttons
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
    // Calculate current accent color (neutral sapphire or brand color)
    final brandColor = brand != null ? _hexToColor(brand!.primaryColor) : null;
    final accentColor = Color.lerp(
      const Color(0xFF6366F1), // Neutral sapphire indigo
      brandColor ?? const Color(0xFF6366F1),
      morphProgress,
    )!;

    return Column(
      children: [
        const Spacer(),

        // Central Monolith Card
        Hero(
          tag: 'brand-portal',
          child: MonolithCard(
            brand: brand,
            morphProgress: morphProgress,
            scale: scale,
          ),
        ),

        const Spacer(),

        // Action buttons (hidden during/after morph)
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
                  _GlassButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR Code',
                    onTap: onScanTap,
                    isPrimary: true,
                    accentColor: accentColor,
                  ),
                  Gap(context.appSizes.paddingMedium),
                  _GlassButton(
                    icon: Icons.search_rounded,
                    label: 'Search by Tag',
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

  /// Parse hex color string to Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return const Color(0xFF6366F1); // Fallback
  }
}

/// Premium glassmorphic button with brand accent colors
class _GlassButton extends HookWidget {
  const _GlassButton({
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
    // Subtle hover/press animation
    final isPressed = useState(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        onTap();
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(isPressed.value ? 0.98 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isPrimary ? 15.0 : 10.0,
              sigmaY: isPrimary ? 15.0 : 10.0,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: context.appSizes.paddingMedium,
                horizontal: context.appSizes.paddingLarge,
              ),
              decoration: BoxDecoration(
                // Subtle glass tint
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
                border: Border.all(
                  width: 1.5,
                  color: Colors.transparent,
                ),
                // Glowing gradient border
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPrimary
                      ? [
                          accentColor.withValues(alpha: 0.4),
                          accentColor.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.15),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  // Glow effect
                  BoxShadow(
                    color: accentColor.withValues(alpha: isPrimary ? 0.25 : 0.15),
                    blurRadius: isPrimary ? 16 : 12,
                    spreadRadius: isPrimary ? 2 : 1,
                  ),
                  // Subtle depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? accentColor : Colors.white,
                    size: 24,
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
        ),
      ),
    );
  }
}

/// QR Scanner overlay with glassmorphic styling
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
            final notifier =
                ref.read(_brandOnboardingNotifierProvider.notifier);

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

        // Glassmorphic scan frame
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

        // Controls
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

/// Glassmorphic icon button
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

/// Loading overlay during processing
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

/// Search view with glassmorphic styling
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
        // Search bar
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

        // Search results
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(context.appSizes.paddingLarge),
            child: searchResult != null
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
                          'Search for your barbershop\nby their unique tag',
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

/// Brand result card with glassmorphic styling
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
            image: brand.logoUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(brand.logoUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: brand.logoUrl.isEmpty
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
          child: _GlassButton(
            icon: Icons.check_circle,
            label: 'Join ${brand.name}',
            onTap: () {
              final currentUserId = ref.read(currentUserIdProvider).valueOrNull;
              final notifier =
                  ref.read(_brandOnboardingNotifierProvider.notifier);
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

  /// Parse hex color string to Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return const Color(0xFF6366F1); // Fallback
  }
}
