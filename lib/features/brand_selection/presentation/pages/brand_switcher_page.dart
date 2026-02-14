import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/home/di.dart';

/// Brand switcher page - allows users with multiple brands to switch between them.
/// For guests: shows previously saved brands from local storage.
/// For authenticated users: shows brands from Firestore user_brands.
class BrandSwitcherPage extends HookConsumerWidget {
  const BrandSwitcherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final selectedBrandId = ref.watch(lockedBrandIdProvider);
    final isLoadingBrand = useState(false);

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n.switchBrand,
          style: context.appTextStyles.bold.copyWith(
            color: context.appColors.primaryTextColor,
          ),
        ),
        backgroundColor: context.appColors.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.appColors.primaryTextColor,
          ),
          onPressed: isLoadingBrand.value ? null : () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: isLoadingBrand.value
                ? null
                : () => context.push(
                      '${AppRoute.brandOnboarding.path}?openScanner=true',
                    ),
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: context.appColors.primaryTextColor,
            ),
            tooltip: context.l10n.discoverBrand,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                isGuest
                    ? _GuestBrandList(
                        selectedBrandId: selectedBrandId,
                        isLoadingBrand: isLoadingBrand,
                        extraBottomPadding: _DiscoveryCTABar.height,
                      )
                    : _AuthenticatedUserBrandList(
                        selectedBrandId: selectedBrandId,
                        isLoadingBrand: isLoadingBrand,
                        extraBottomPadding: _DiscoveryCTABar.height,
                      ),
                if (isLoadingBrand.value) _BrandLoadingOverlay(),
              ],
            ),
          ),
          _DiscoveryCTABar(
            onDiscover: () => context.push(AppRoute.brandOnboarding.path),
            enabled: !isLoadingBrand.value,
          ),
        ],
      ),
    );
  }
}

/// Brand list for authenticated users (from Firestore user_brands).
class _AuthenticatedUserBrandList extends HookConsumerWidget {
  const _AuthenticatedUserBrandList({
    required this.selectedBrandId,
    required this.isLoadingBrand,
    this.extraBottomPadding = 0,
  });

  final String? selectedBrandId;
  final ValueNotifier<bool> isLoadingBrand;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBrandsAsync = ref.watch(userBrandsProvider);

    return userBrandsAsync.when(
      data: (userBrands) {
        if (userBrands.isEmpty) {
          return const _EmptyState();
        }

        return _BrandList(
          brandIds: userBrands.map((ub) => ub.brandId).toList(),
          selectedBrandId: selectedBrandId,
          isLoadingBrand: isLoadingBrand,
          extraBottomPadding: extraBottomPadding,
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => _ErrorState(message: error.toString()),
    );
  }
}

/// Brand list for guests (from local storage).
class _GuestBrandList extends HookConsumerWidget {
  const _GuestBrandList({
    required this.selectedBrandId,
    required this.isLoadingBrand,
    this.extraBottomPadding = 0,
  });

  final String? selectedBrandId;
  final ValueNotifier<bool> isLoadingBrand;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestBrandIds = ref.watch(guestBrandIdsProvider);

    if (guestBrandIds.isEmpty) {
      return const _EmptyState();
    }

    return _BrandList(
      brandIds: guestBrandIds,
      selectedBrandId: selectedBrandId,
      isLoadingBrand: isLoadingBrand,
      extraBottomPadding: extraBottomPadding,
    );
  }
}

class _BrandList extends HookConsumerWidget {
  const _BrandList({
    required this.brandIds,
    required this.selectedBrandId,
    required this.isLoadingBrand,
    this.extraBottomPadding = 0,
  });

  final List<String> brandIds;
  final String? selectedBrandId;
  final ValueNotifier<bool> isLoadingBrand;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = context.appSizes.paddingMedium;
    final bottomInset = extraBottomPadding > 0
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        padding + extraBottomPadding + bottomInset,
      ),
      itemCount: brandIds.length,
      separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
      itemBuilder: (context, index) {
        final brandId = brandIds[index];
        return _BrandCard(
          brandId: brandId,
          isSelected: brandId == selectedBrandId,
          isLoadingBrand: isLoadingBrand,
        );
      },
    );
  }
}

class _BrandCard extends HookConsumerWidget {
  const _BrandCard({
    required this.brandId,
    required this.isSelected,
    required this.isLoadingBrand,
  });

  final String brandId;
  final bool isSelected;
  final ValueNotifier<bool> isLoadingBrand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandAsync = ref.watch(brandByIdProvider(brandId));

    return brandAsync.when(
      data: (brandOrNull) {
        final brand = brandOrNull.fold(
          (_) => null,
          (b) => b,
        );

        if (brand == null) {
          return const SizedBox.shrink();
        }

        return _BrandCardContent(
          brand: brand,
          isSelected: isSelected,
          onTap: () => _handleBrandSwitch(context, ref, brand),
        );
      },
      loading: () => const _BrandCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleBrandSwitch(
    BuildContext context,
    WidgetRef ref,
    BrandEntity brand,
  ) async {
    if (isSelected) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SwitchConfirmDialog(brandName: brand.name),
    );

    if (confirm != true || !context.mounted) return;

    // Set loading state
    isLoadingBrand.value = true;

    try {
      // Set theme override IMMEDIATELY from brand entity to prevent default config flash
      // This ensures the UI shows the correct brand colors right away
      if (brand.themeColors.isNotEmpty) {
        ref.read(themeOverrideProvider.notifier).state = brand.themeColors;
        debugPrint('[BrandSwitcher] Theme override set immediately from brand entity');
      } else {
        // Clear override if brand has no theme colors
        ref.read(themeOverrideProvider.notifier).state = null;
      }

      // Small delay to ensure theme propagates
      await Future.delayed(const Duration(milliseconds: 50));

      // Now set the locked brand ID
      ref.read(lockedBrandIdProvider.notifier).state = brand.brandId;
      debugPrint('[BrandSwitcher] Locked brand set: ${brand.brandId}');

      // Invalidate providers to ensure fresh fetch
      ref.invalidate(defaultBrandProvider);
      ref.invalidate(userBrandsProvider);
      ref.invalidate(homeNotifierProvider);
      ref.invalidate(upcomingAppointmentProvider);

      // Wait for brand config to fully load (this will update theme override if needed)
      await ref.read(defaultBrandProvider.future);
      debugPrint('[BrandSwitcher] Brand config loaded');

      // Wait for theme to fully propagate
      await Future.delayed(const Duration(milliseconds: 150));

      // Ensure app colors provider has updated
      ref.read(appColorsProvider);
      debugPrint('[BrandSwitcher] Theme fully propagated');
    } catch (e) {
      debugPrint('[BrandSwitcher] Error loading brand config: $e');
      // Reset theme override on error
      ref.read(themeOverrideProvider.notifier).state = null;
      if (context.mounted) {
        isLoadingBrand.value = false;
        return;
      }
    } finally {
      isLoadingBrand.value = false;
    }

    if (context.mounted) {
      // Pop the dialog first
      context.pop();
      
      // Then manually navigate to home after a brief delay to ensure
      // the dialog is fully dismissed and UI has updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (context.mounted) {
        context.go(AppRoute.home.path);
      }
    }
  }
}

class _BrandCardContent extends StatelessWidget {
  const _BrandCardContent({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final BrandEntity brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.menuBackgroundColor,
      borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Row(
            children: [
              // Brand logo
              if (brand.logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    brand.logoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => _BrandLogoPlaceholder(
                          brandName: brand.name,
                        ),
                  ),
                )
              else
                _BrandLogoPlaceholder(brandName: brand.name),
              Gap(context.appSizes.paddingMedium),
              // Brand name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      style: context.appTextStyles.medium.copyWith(
                        color: context.appColors.primaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                    if (isSelected) ...[
                      const Gap(4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.primaryColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.currentBrand,
                          style: context.appTextStyles.caption.copyWith(
                            color: context.appColors.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Checkmark
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: context.appColors.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogoPlaceholder extends StatelessWidget {
  const _BrandLogoPlaceholder({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.appColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          brandName.isNotEmpty ? brandName[0].toUpperCase() : '?',
          style: context.appTextStyles.bold.copyWith(
            color: context.appColors.primaryColor,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class _BrandCardSkeleton extends StatelessWidget {
  const _BrandCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      ),
    );
  }
}

class _SwitchConfirmDialog extends StatelessWidget {
  const _SwitchConfirmDialog({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.switchBrandConfirmTitle),
      content: Text(context.l10n.switchBrandConfirmMessage(brandName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.switchBrandButton),
        ),
      ],
    );
  }
}

/// Fixed bottom CTA that navigates to discovery portal (normal flow, no scanner).
class _DiscoveryCTABar extends StatelessWidget {
  const _DiscoveryCTABar({
    required this.onDiscover,
    required this.enabled,
  });

  final VoidCallback onDiscover;
  final bool enabled;

  static double get height => 56 + 16 * 2; // button + vertical padding

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          context.appSizes.paddingMedium,
          context.appSizes.paddingMedium,
          context.appSizes.paddingMedium,
          context.appSizes.paddingMedium + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: context.appColors.backgroundColor,
        ),
        child: FilledButton.icon(
          onPressed: enabled ? onDiscover : null,
          icon: const Icon(Icons.add_business_rounded, size: 22),
          label: Text(context.l10n.discoverBrand),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_mall_directory_outlined,
              size: 64,
              color: context.appColors.secondaryTextColor,
            ),
            Gap(context.appSizes.paddingMedium),
            Text(
              context.l10n.noBrandsFound,
              style: context.appTextStyles.body.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
            ),
            Gap(context.appSizes.paddingSmall),
            Text(
              context.l10n.discoverBrandsHint,
              style: context.appTextStyles.caption.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingLarge),
        child: Text(
          message,
          style: context.appTextStyles.body.copyWith(
            color: context.appColors.errorColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Loading overlay shown while brand config is loading
class _BrandLoadingOverlay extends StatelessWidget {
  const _BrandLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
