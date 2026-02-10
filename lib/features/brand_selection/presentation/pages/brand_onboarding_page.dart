import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/core/utils/debug_seeder.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/brand_selection/presentation/bloc/brand_onboarding_notifier.dart';

final _brandOnboardingNotifierProvider = StateNotifierProvider.autoDispose<
  BrandOnboardingNotifier,
  BaseState<BrandOnboardingState>
>((ref) {
  final brandRepo = ref.watch(brandRepositoryProvider);
  final userBrandsRepo = ref.watch(userBrandsRepositoryProvider);
  return BrandOnboardingNotifier(brandRepo, userBrandsRepo);
});

class BrandOnboardingPage extends HookConsumerWidget {
  const BrandOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showScanner = useState(false);

    // Listen for state changes (Success/Error)
    ref.listen<BaseState<BrandOnboardingState>>(
      _brandOnboardingNotifierProvider,
      (prev, next) {
        if (next is BaseData<BrandOnboardingState>) {
          final state = next.data;
          if (state.errorMessage != null) {
            showErrorSnackBar(context, message: state.errorMessage!);
          } else if (state.selectedBrand != null) {
            // Success: Update global selected brand and Navigate
            ref.read(selectedBrandIdProvider.notifier).state =
                state.selectedBrand!.brandId;
            context.go(AppRoute.home.path);
          }
        }
      },
    );

    // Handle Back Button to close scanner if open
    // PopScope replaces WillPopScope
    return PopScope(
      canPop: !showScanner.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (showScanner.value) {
          showScanner.value = false;
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.backgroundColor,
        appBar:
            showScanner.value
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
                        // If can't pop (e.g. initial route), go home or stay?
                        // Usually implies user wants to leave onboarding.
                        // If they have brands, home is fine. If not, maybe logout?
                        // We'll stick to pop or home.
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
                    : _SelectionMenu(
                      onScanTap: () => showScanner.value = true,
                      onSearchTap: () {
                        // Placeholder for Search UI
                        showInfoSnackBar(
                          context,
                          message: 'Search feature coming soon',
                        );
                      },
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
              'Find Your Barbershop',
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
            label: 'Scan QR Code',
            onTap: onScanTap,
            isPrimary: true,
          ),
          Gap(context.appSizes.paddingMedium),
          _ActionButton(
            icon: Icons.search_rounded,
            label: 'Search by Name',
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

            if (userId != null) {
              await ref
                  .read(_brandOnboardingNotifierProvider.notifier)
                  .handleQrCode(raw, userId);
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
