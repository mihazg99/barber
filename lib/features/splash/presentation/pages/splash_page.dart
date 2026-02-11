import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/features/brand/di.dart' as brand_di;
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Branded splash screen. Shown while loading user and determining destination.
/// Prefetches brand for cache; router redirect handles navigation to onboarding,
/// auth, home, or dashboard based on user role.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefetch brand so home/dashboard get cached data when we navigate.
    // Only do this when a brand is actually locked to avoid unnecessary reads.
    final lockedBrandId = ref.watch(brand_di.lockedBrandIdProvider);
    if (lockedBrandId != null && lockedBrandId.isNotEmpty) {
      ref.watch(brand_di.defaultBrandProvider);
    }

    return const Scaffold(
      body: _SplashBody(),
    );
  }
}

class _SplashBody extends ConsumerWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandAsync = ref.watch(brand_di.defaultBrandProvider);
    final logoUrl = brandAsync.valueOrNull?.logoUrl;
    final brandName =
        brandAsync.valueOrNull?.name ??
        ref.watch(flavorConfigProvider).values.brandConfig.appTitle;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.appColors.backgroundColor,
            context.appColors.navigationBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: _SplashContent(
          logoUrl: logoUrl,
          brandName: brandName,
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    this.logoUrl,
    required this.brandName,
  });

  final String? logoUrl;
  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BrandLogo(logoUrl: logoUrl, brandName: brandName),
          SizedBox(height: context.appSizes.paddingXxl),
          const _LoadingIndicator(),
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({
    this.logoUrl,
    required this.brandName,
  });

  final String? logoUrl;
  final String brandName;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Image.network(
          logoUrl!,
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _FallbackLogo(brandName: brandName),
        ),
      );
    }
    return _FallbackLogo(brandName: brandName);
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final initial = brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B';
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: context.appColors.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius * 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: context.appTextStyles.headline.copyWith(
          fontSize: 48,
          color: context.appColors.primaryColor,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.appColors.primaryColor.withValues(alpha: 0.8),
      ),
    );
  }
}
