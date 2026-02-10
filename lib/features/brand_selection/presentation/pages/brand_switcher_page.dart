import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand_selection/di.dart';

/// Brand switcher page - allows users with multiple brands to switch between them.
class BrandSwitcherPage extends HookConsumerWidget {
  const BrandSwitcherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBrandsAsync = ref.watch(userBrandsProvider);
    final selectedBrandId = ref.watch(selectedBrandIdProvider);

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Switch Barbershop',
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
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoute.brandOnboarding.path),
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: context.appColors.primaryTextColor,
            ),
            tooltip: 'Add Barbershop',
          ),
        ],
      ),
      body: userBrandsAsync.when(
        data: (userBrands) {
          if (userBrands.isEmpty) {
            return const _EmptyState();
          }

          return _BrandList(
            userBrands: userBrands,
            selectedBrandId: selectedBrandId,
          );
        },
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(message: error.toString()),
      ),
    );
  }
}

class _BrandList extends HookConsumerWidget {
  const _BrandList({
    required this.userBrands,
    required this.selectedBrandId,
  });

  final List userBrands;
  final String? selectedBrandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      itemCount: userBrands.length,
      separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
      itemBuilder: (context, index) {
        final userBrand = userBrands[index];
        return _BrandCard(
          brandId: userBrand.brandId,
          isSelected: userBrand.brandId == selectedBrandId,
        );
      },
    );
  }
}

class _BrandCard extends HookConsumerWidget {
  const _BrandCard({
    required this.brandId,
    required this.isSelected,
  });

  final String brandId;
  final bool isSelected;

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

    // Switch brand
    ref.read(selectedBrandIdProvider.notifier).state = brand.brandId;

    // Invalidate all providers to refresh UI
    ref.invalidate(userBrandsProvider);

    if (context.mounted) {
      context.pop();
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
                          'Current',
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
      title: const Text('Switch Barbershop'),
      content: Text('Switch to $brandName?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Switch'),
        ),
      ],
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
        child: Text(
          'No barbershops found',
          style: context.appTextStyles.body.copyWith(
            color: context.appColors.secondaryTextColor,
          ),
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
