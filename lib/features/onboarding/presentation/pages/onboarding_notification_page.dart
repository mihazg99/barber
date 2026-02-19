import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/glass_container.dart';
import 'package:barber/core/widgets/video_background.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/onboarding/di.dart';
import 'package:barber/core/widgets/glass_button.dart';

/// Onboarding step that explains push notifications and asks for permission.
/// Same visual design as onboarding slides (video background, glass containers).
class OnboardingNotificationPage extends ConsumerStatefulWidget {
  const OnboardingNotificationPage({super.key});

  @override
  ConsumerState<OnboardingNotificationPage> createState() =>
      _OnboardingNotificationPageState();
}

class _OnboardingNotificationPageState
    extends ConsumerState<OnboardingNotificationPage> {
  bool _isCompleting = false;
  bool _isRequestingPermission = false;

  Future<void> _enableReminders() async {
    if (_isRequestingPermission || _isCompleting) return;
    setState(() => _isRequestingPermission = true);
    try {
      await ref
          .read(pushNotificationNotifierProvider.notifier)
          .refreshPermissionAndToken();
    } finally {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
    await _completeAndGoHome();
  }

  Future<void> _skipNotifications() async {
    if (_isCompleting) return;
    await _completeAndGoHome();
  }

  Future<void> _completeAndGoHome() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    final success =
        await ref.read(onboardingNotifierProvider.notifier).complete();
    if (!mounted) return;
    if (!success) {
      setState(() => _isCompleting = false);
      return;
    }
    ref.invalidate(onboardingHasCompletedProvider);
    ref.read(videoPreloaderServiceProvider).portalVideoController?.pause();

    // Check if brand is locked. If not, go to portal.
    // (Router would eventually fix this but better to be explicit)
    final lockedBrand = ref.read(lockedBrandIdProvider);
    if (lockedBrand == null || lockedBrand.isEmpty) {
      context.go(AppRoute.brandOnboarding.path);
    } else {
      context.go(AppRoute.home.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: VideoBackground(
              baseColor: context.appColors.backgroundColor,
              opacity: 0.65,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomGradientMask(
              backgroundColor: context.appColors.backgroundColor,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    constraints.maxWidth > 400 ? 400.0 : constraints.maxWidth;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.appSizes.paddingLarge,
                    vertical: context.appSizes.paddingXl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          context.appSizes.paddingXl * 2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon: single clear focus
                        GlassContainer(
                          borderRadius: context.appSizes.borderRadius * 1.5,
                          backgroundColor: context.appColors.primaryColor
                              .withValues(alpha: 0.12),
                          borderColor: context.appColors.primaryColor
                              .withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: Center(
                              child: Icon(
                                Icons.notifications_active_outlined,
                                size: 56,
                                color: context.appColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        Gap(context.appSizes.paddingXxl),
                        // Copy: benefit-first, constrained for readability
                        SizedBox(
                          width: contentWidth,
                          child: GlassContainer(
                            borderRadius: context.appSizes.borderRadius * 1.5,
                            padding: EdgeInsets.all(
                              context.appSizes.paddingLarge,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.onboardingNotificationsTitle,
                                  textAlign: TextAlign.center,
                                  style: context.appTextStyles.headline
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                ),
                                Gap(context.appSizes.paddingMedium),
                                Text(
                                  l10n.onboardingNotificationsDescription,
                                  textAlign: TextAlign.center,
                                  style: context.appTextStyles.body.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 16,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Gap(context.appSizes.paddingXxl),
                        // Primary CTA: one clear action
                        SizedBox(
                          width: double.infinity,
                          child: GlassPrimaryButton(
                            label: l10n.enableReminders,
                            onTap: _isCompleting ? null : _enableReminders,
                            loading: _isRequestingPermission,
                            enabled: !_isCompleting,
                            accentColor: context.appColors.primaryColor,
                          ),
                        ),
                        Gap(context.appSizes.paddingLarge),
                        // Secondary: low emphasis, no guilt
                        TextButton(
                          onPressed: _isCompleting ? null : _skipNotifications,
                          style: TextButton.styleFrom(
                            foregroundColor: context.appColors.captionTextColor,
                            padding: EdgeInsets.symmetric(
                              vertical: context.appSizes.paddingSmall,
                              horizontal: context.appSizes.paddingMedium,
                            ),
                          ),
                          child: Text(
                            l10n.notNow,
                            style: context.appTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomGradientMask extends StatelessWidget {
  const _BottomGradientMask({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            backgroundColor,
          ],
        ),
      ),
    );
  }
}
