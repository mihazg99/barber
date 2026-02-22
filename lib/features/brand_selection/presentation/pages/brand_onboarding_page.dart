import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/core/utils/debug_seeder.dart';
import 'package:barber/core/widgets/glass_button.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/brand_selection/presentation/bloc/brand_onboarding_notifier.dart';

final _brandOnboardingNotifierProvider = StateNotifierProvider.autoDispose<
  BrandOnboardingNotifier,
  BaseState<BrandOnboardingState>
>((ref) {
  final brandRepo = ref.watch(brandRepositoryProvider);
  final userBrandsRepo = ref.watch(userBrandsRepositoryProvider);
  final guestStorage = ref.watch(guestStorageProvider);
  return BrandOnboardingNotifier(brandRepo, userBrandsRepo, guestStorage);
});

class BrandOnboardingPage extends HookConsumerWidget {
  const BrandOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showScanner = useState(false);
    final showSearch = useState(false);

    // Listen for state changes (Success/Error)
    ref.listen<BaseState<BrandOnboardingState>>(
      _brandOnboardingNotifierProvider,
      (prev, next) {
        debugPrint(
          '[BrandOnboarding Listener] State changed: prev=$prev, next=$next',
        );
        if (next is BaseData<BrandOnboardingState>) {
          final state = next.data;
          if (state.errorMessage != null) {
            debugPrint('[BrandOnboarding] Error: ${state.errorMessage}');
            showErrorSnackBar(context, message: state.errorMessage!);
          } else if (state.selectedBrand != null) {
            // Success: Update global selected brand and Navigate
            final brandId = state.selectedBrand!.brandId;
            debugPrint('[BrandOnboarding] Setting locked brand: $brandId');
            ref.read(lockedBrandIdProvider.notifier).state = brandId;
            debugPrint('[BrandOnboarding] Navigating to home via context.go');
            context.go(AppRoute.home.path);
          }
        }
      },
    );

    // Handle Back Button to close scanner/search if open
    // PopScope replaces WillPopScope
    return PopScope(
      canPop: !showScanner.value && !showSearch.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (showScanner.value) {
          showScanner.value = false;
        } else if (showSearch.value) {
          showSearch.value = false;
          // Clean up search state
          ref.read(_brandOnboardingNotifierProvider.notifier).clearSearch();
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.backgroundColor,
        appBar:
            (showScanner.value || showSearch.value)
                ? null
                : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.appColors.primaryTextColor,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoute.home.path);
                      }
                    },
                  ),
                ),
        body: SafeArea(
          child: AnimatedSwitcher(
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
                    : _SelectionMenu(
                      onScanTap: () => showScanner.value = true,
                      onSearchTap: () => showSearch.value = true,
                    ),
          ),
        ),
      ),
    );
  }
}

class _SelectionMenu extends HookConsumerWidget {
  const _SelectionMenu({
    required this.onScanTap,
    required this.onSearchTap,
  });

  final VoidCallback onScanTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_brandOnboardingNotifierProvider);
    final isLoading =
        state is BaseData<BrandOnboardingState> && state.data.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(context.appSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // Icon
          Icon(
            Icons.storefront_rounded,
            size: 80,
            color: context.appColors.primaryColor,
          ),
          Gap(context.appSizes.paddingLarge),

          // Title with secret trigger
          GestureDetector(
            onDoubleTap: () async {
              final brandId = await createTestBrand();
              if (context.mounted) {
                showSuccessSnackBar(
                  context,
                  message: 'Test brand created: $brandId',
                );
              }
            },
            child: Text(
              context.l10n.findYourBusiness,
              style: context.appTextStyles.h1.copyWith(
                color: context.appColors.primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Gap(context.appSizes.paddingSmall),

          Text(
            'Connect with your favorite barber',
            style: context.appTextStyles.body.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Actions
          _ActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: context.l10n.scanQrCode,
            onTap: onScanTap,
            isPrimary: true,
          ),
          Gap(context.appSizes.paddingMedium),
          _ActionButton(
            icon: Icons.search_rounded,
            label: context.l10n.searchByTag,
            onTap: onSearchTap,
            isPrimary: false,
          ),
          Gap(context.appSizes.paddingXxl),
        ],
      ),
    );
  }
}

class _ActionButton extends HookConsumerWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: isPrimary ? context.appColors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.appSizes.paddingMedium,
            horizontal: context.appSizes.paddingLarge,
          ),
          decoration:
              isPrimary
                  ? null
                  : BoxDecoration(
                    border: Border.all(
                      color: context.appColors.primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(
                      context.appSizes.borderRadius,
                    ),
                  ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isPrimary ? Colors.white : context.appColors.primaryColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                label,
                style: context.appTextStyles.button.copyWith(
                  color:
                      isPrimary ? Colors.white : context.appColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    // Prevent multiple detections
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

            // Allow re-scan after delay if needed (e.g. error)
            await Future.delayed(const Duration(seconds: 2));
            if (context.mounted) {
              isProcessing.value = false;
            }
          },
        ),

        // Scan Overlay Frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
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
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    onPressed: () => controller.toggleTorch(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading Indicator
        const _LoadingOverlay(),
      ],
    );
  }
}

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
        // App Bar with search input
        Padding(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.appColors.primaryTextColor,
                ),
                onPressed: onClose,
              ),
              Expanded(
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: context.appTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'brand-tag',
                    hintStyle: context.appTextStyles.body.copyWith(
                      color: context.appColors.secondaryTextColor,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.appColors.secondaryTextColor,
                    ),
                    prefixText: '@',
                    prefixStyle: context.appTextStyles.body.copyWith(
                      color: context.appColors.primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.appColors.primaryColor,
                      ),
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
            ],
          ),
        ),

        if (isLoading) const LinearProgressIndicator(),

        // Content
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
                            color: context.appColors.errorColor,
                          ),
                          Gap(context.appSizes.paddingMedium),
                          Text(
                            data?.errorMessage ?? '',
                            style: context.appTextStyles.body.copyWith(
                              color: context.appColors.errorColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : Center(
                      child: Text(
                        context.l10n.searchBusinessByTagSingleLine,
                        style: context.appTextStyles.body.copyWith(
                          color: context.appColors.secondaryTextColor,
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
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
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
                  ? Icon(Icons.store, size: 60, color: Colors.grey[400])
                  : null,
        ),
        Gap(context.appSizes.paddingLarge),
        Text(
          brand.name,
          style: context.appTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        if (brand.tag != null) ...[
          Gap(context.appSizes.paddingSmall),
          Text(
            '@${brand.tag}',
            style: context.appTextStyles.body.copyWith(
              color: context.appColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        Gap(context.appSizes.paddingXxl),

        SizedBox(
          width: double.infinity,
          child: GlassPrimaryButton(
            icon: Icons.check_circle,
            label: context.l10n.joinBrand(brand.name),
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
            accentColor: context.appColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
