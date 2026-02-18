import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/router/app_stage.dart';
import 'package:barber/core/router/app_stage_notifier.dart'; // Import AppStage for initialization check
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/presentation/bloc/login_overlay_notifier.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/data/country_code.dart';
import 'package:barber/features/auth/presentation/widgets/country_code_selector.dart';

/// Premium contextual login overlay modal with glassmorphism.
/// Appears as a glassmorphism card over the current view without route changes.
class LoginOverlay extends HookConsumerWidget {
  const LoginOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CRITICAL: Check App Stage first.
    // If the app is still initializing (Splash screen), we must NOT show the overlay.
    // The "isProfileComplete" check defaults to false during loading, which causes a flash.
    final appStageState = ref.watch(appStageProvider);
    if (appStageState is LoadingStage) {
      return const SizedBox.shrink();
    }

    final overlayState = ref.watch(loginOverlayNotifierProvider);
    final overlayData =
        overlayState is BaseData<LoginOverlayState> ? overlayState.data : null;

    // Watch auth state to detect profile completion step
    final authState = ref.watch(authNotifierProvider);
    final authData =
        authState is BaseData<AuthFlowData> ? authState.data : null;
    final needsProfileCompletion = authData?.isProfileInfo ?? false;

    // Force visibility if authenticated but profile incomplete
    // This ensures the overlay blocks usage until profile is done.
    final isAuthenticated =
        ref.watch(isAuthenticatedProvider).valueOrNull ?? false;
    final isProfileComplete = ref.watch(isProfileCompleteProvider);

    // If profile is incomplete, we MUST show the overlay and force profile step
    final forceProfileCompletion = isAuthenticated && !isProfileComplete;

    // Use the most up-to-date user object available
    final lastSignedIn = ref.watch(lastSignedInUserProvider);
    final currentUserStream = ref.watch(currentUserProvider).valueOrNull;
    final effectiveUser = authData?.user ?? lastSignedIn ?? currentUserStream;

    if (!forceProfileCompletion &&
        (overlayData == null || !overlayData.isVisible)) {
      return const SizedBox.shrink();
    }

    // Animation controller for fade + slide up
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // Start animation when overlay becomes visible
    useEffect(() {
      final isVisible =
          forceProfileCompletion || (overlayData?.isVisible ?? false);
      if (isVisible) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [overlayData?.isVisible, forceProfileCompletion]);

    // Fade animation
    final fadeAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Slide up animation
    final slideAnimation = useAnimation(
      Tween<double>(begin: 0.3, end: 0.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut,
        ),
      ),
    );

    final showProfileCompletion =
        (needsProfileCompletion || forceProfileCompletion) &&
        effectiveUser != null;

    return IgnorePointer(
      ignoring: !(forceProfileCompletion || (overlayData?.isVisible ?? false)),
      child: FadeTransition(
        opacity: AlwaysStoppedAnimation(fadeAnimation),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Backdrop - transparent (blur is applied only to the card itself)
              // Disable tap to dismiss when profile completion is required
              Positioned.fill(
                child: GestureDetector(
                  onTap:
                      needsProfileCompletion || forceProfileCompletion
                          ? null
                          : () =>
                              ref
                                  .read(loginOverlayNotifierProvider.notifier)
                                  .hide(),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Modal card
              Center(
                child: Transform.translate(
                  offset: Offset(0, slideAnimation * 100),
                  child: _LoginModalCard(
                    isLoading: overlayData?.isLoading ?? false,
                    errorMessage: overlayData?.errorMessage,
                    needsProfileCompletion:
                        needsProfileCompletion || forceProfileCompletion,
                    profileUser: effectiveUser,
                    onGoogleSignIn: () => _handleGoogleSignIn(context, ref),
                    onProfileSubmit:
                        showProfileCompletion
                            ? (fullName, phone) => _handleProfileSubmit(
                              context,
                              ref,
                              effectiveUser!,
                              fullName,
                              phone,
                            )
                            : null,
                    onClose:
                        () =>
                            ref
                                .read(loginOverlayNotifierProvider.notifier)
                                .hide(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final overlayNotifier = ref.read(loginOverlayNotifierProvider.notifier);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final flavorConfig = ref.read(flavorConfigProvider);

    overlayNotifier.setLoadingState(true);

    // Sign in with Google
    await authNotifier.signInWithGoogle(
      requireSmsVerification:
          flavorConfig.values.brandConfig.requireSmsVerification,
    );

    if (!context.mounted) return;

    // Check auth state after sign-in attempt
    final authState = ref.read(authNotifierProvider);
    if (authState is BaseData<AuthFlowData>) {
      final authData = authState.data;
      if (authData.errorMessage != null && authData.errorMessage!.isNotEmpty) {
        overlayNotifier.setErrorMessage(authData.errorMessage!);
      } else if (authData.isProfileInfo) {
        // Profile completion needed - keep overlay visible
        overlayNotifier.setLoadingState(false);
      } else {
        // Success - hide overlay
        overlayNotifier.hide();
      }
    } else if (authState case BaseError<AuthFlowData>(:final message)) {
      overlayNotifier.setErrorMessage(message);
    } else {
      // Loading or initial state - keep overlay visible
    }
  }

  Future<void> _handleProfileSubmit(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
    String fullName,
    String phone,
  ) async {
    final overlayNotifier = ref.read(loginOverlayNotifierProvider.notifier);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    overlayNotifier.setLoadingState(true);

    await authNotifier.submitProfile(user, fullName, phone);

    if (!context.mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is BaseData<AuthFlowData>) {
      final authData = authState.data;
      if (authData.errorMessage != null && authData.errorMessage!.isNotEmpty) {
        overlayNotifier.setErrorMessage(authData.errorMessage!);
      } else {
        // Success - hide overlay and refresh user data
        overlayNotifier.hide();
        // Invalidate currentUserProvider to ensure isProfileComplete updates
        // before router redirect logic runs
        ref.invalidate(currentUserProvider);
        // Delay router refresh to allow currentUserProvider to update
        Future.delayed(const Duration(milliseconds: 100), () {
          ref.read(routerRefreshNotifierProvider).notify();
        });
      }
    } else if (authState case BaseError<AuthFlowData>(:final message)) {
      overlayNotifier.setErrorMessage(message);
    }
  }
}

/// The premium glassmorphism modal card containing login UI.
class _LoginModalCard extends HookConsumerWidget {
  const _LoginModalCard({
    required this.isLoading,
    this.errorMessage,
    required this.needsProfileCompletion,
    this.profileUser,
    required this.onGoogleSignIn,
    this.onProfileSubmit,
    required this.onClose,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool needsProfileCompletion;
  final UserEntity? profileUser;
  final VoidCallback onGoogleSignIn;
  final Future<void> Function(String fullName, String phone)? onProfileSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final flavorConfig = ref.watch(flavorConfigProvider);
    final brandConfig = flavorConfig.values.brandConfig;

    // Obsidian glass background - high-transparency black (NO brown/tan/gold)
    final cardBackgroundColor = Colors.black.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {}, // Prevent tap from closing when clicking inside card
      child: Container(
        // Fixed height container - does not resize during transitions
        constraints: const BoxConstraints(
          maxWidth: 400,
          minHeight: 300,
        ),
        height: 400, // Fixed height for consistent transitions
        margin: EdgeInsets.symmetric(horizontal: sizes.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Very subtle, dark diffused shadow for "lift" effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            // Outer container with hairline gradient border (0.6px width)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryColor, // brand.colors.primary at top-left
                  Colors.transparent, // Transparent at bottom-right
                ],
              ),
            ),
            // Inner container with backdrop filter and content (creates border effect)
            child: Padding(
              padding: const EdgeInsets.all(
                0.6,
              ), // 0.6px border width (hairline gradient edge)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  23.4,
                ), // Slightly smaller to account for 0.6px border
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 25.0,
                    sigmaY: 25.0,
                  ), // Floating Obsidian Glass blur
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(23.4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: SingleChildScrollView(
                        // Keyboard-aware scrolling
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Close button - very thin, top-right, 50% opacity
                            // Hide close button when profile completion is required
                            if (!needsProfileCompletion)
                              Align(
                                alignment: Alignment.topRight,
                                child: _CloseButton(onClose: onClose),
                              ),
                            Gap(sizes.paddingSmall),
                            // Brand logo
                            if (brandConfig.logoPath.isNotEmpty) ...[
                              _BrandLogo(logoPath: brandConfig.logoPath),
                              Gap(sizes.paddingXl),
                            ],
                            // Multi-step content with fade/slide transition
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) {
                                // Fade + slide transition (content fades/slides out/in, container stays static)
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(
                                      0.0,
                                      0.1,
                                    ), // Subtle vertical slide
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child:
                                  needsProfileCompletion && profileUser != null
                                      ? _ProfileCompletionStep(
                                        key: const ValueKey('profile'),
                                        user: profileUser!,
                                        isLoading: isLoading,
                                        errorMessage: errorMessage,
                                        onSubmit: onProfileSubmit!,
                                      )
                                      : _LoginStep(
                                        key: const ValueKey('login'),
                                        isLoading: isLoading,
                                        errorMessage: errorMessage,
                                        onGoogleSignIn: onGoogleSignIn,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Login step - minimalist Google Auth button.
class _LoginStep extends ConsumerWidget {
  const _LoginStep({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.onGoogleSignIn,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sizes = context.appSizes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Headline - "Dobrodošli" in brand.colors.primary, Poppins Bold, 1.5 letter spacing
        Text(
          'Dobrodošli',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.primaryColor, // brand.colors.primary
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        Gap(sizes.paddingXxl),
        // Google Sign In Button - Solid Gold Bar with vertical gradient
        _GoogleSignInButton(
          onPressed: isLoading ? null : onGoogleSignIn,
          isLoading: isLoading,
        ),
        // Error message
        if (errorMessage != null) ...[
          Gap(sizes.paddingMedium),
          _ErrorText(message: errorMessage!),
        ],
      ],
    );
  }
}

/// Profile completion step with ghost inputs.
class _ProfileCompletionStep extends HookConsumerWidget {
  const _ProfileCompletionStep({
    super.key,
    required this.user,
    required this.isLoading,
    this.errorMessage,
    required this.onSubmit,
  });

  final UserEntity user;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(String fullName, String phone) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final textStyles = context.appTextStyles;
    final flavorConfig = ref.watch(flavorConfigProvider);
    final brandConfig = flavorConfig.values.brandConfig;

    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final selectedCountry = useState<CountryCode>(
      kCountryCodes.firstWhere(
        (c) => c.isoCode == 'HR',
        orElse: () => kCountryCodes.first,
      ),
    );

    // Pre-fill name if user already has one
    useEffect(() {
      if (user.fullName.isNotEmpty) {
        nameController.text = user.fullName;
      }
      return null;
    }, []);

    // Pre-fill phone if user already has one
    useEffect(() {
      if (user.phone.isNotEmpty) {
        final phone = user.phone;
        final matchingCountry = kCountryCodes.firstWhere(
          (c) => phone.startsWith(c.dialCode),
          orElse: () => selectedCountry.value,
        );
        selectedCountry.value = matchingCountry;
        final phoneWithoutCode = phone.replaceFirst(
          matchingCountry.dialCode,
          '',
        );
        phoneController.text = phoneWithoutCode;
      }
      return null;
    }, []);

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.authCompleteProfile,
            style: textStyles.bold.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.primaryColor,
              fontFamily: brandConfig.fontFamily,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: colors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Gap(sizes.paddingMedium),
          Text(
            context.l10n.authProfileDescription,
            style: textStyles.body.copyWith(
              fontSize: 14,
              color: colors.secondaryTextColor,
              fontFamily: brandConfig.fontFamily,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(sizes.paddingXxl),
          // Ghost input for name
          _GhostTextField(
            controller: nameController,
            label: context.l10n.authFullName,
            hint: context.l10n.authFullNameHint,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return context.l10n.authFullNameValidation;
              }
              return null;
            },
          ),
          Gap(sizes.paddingXl),
          // Ghost input for phone
          Text(
            context.l10n.authPhoneNumber,
            style: textStyles.h2.copyWith(
              color: colors.secondaryTextColor,
              fontSize: 14,
              fontFamily: brandConfig.fontFamily,
              letterSpacing: 1.5,
            ),
          ),
          Gap(sizes.paddingSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountryCodeSelector(
                selected: selectedCountry.value,
                onChanged: (c) => selectedCountry.value = c,
                enabled: !isLoading,
              ),
              Gap(sizes.paddingMedium),
              Expanded(
                child: _GhostTextField(
                  controller: phoneController,
                  hint: context.l10n.authPhoneHint,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    final digits = _digitsOnly(v ?? '');
                    if (digits.length < 6) {
                      return context.l10n.authPhoneValidation;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            Gap(sizes.paddingMedium),
            _ErrorText(message: errorMessage!),
          ],
          Gap(sizes.paddingXl),
          // Premium Save button - metallic gold appearance
          _PremiumSaveButton(
            onPressed:
                isLoading
                    ? null
                    : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final digits = _digitsOnly(phoneController.text);
                        final fullPhone =
                            selectedCountry.value.dialCode + digits;
                        await onSubmit(
                          nameController.text.trim(),
                          fullPhone,
                        );
                      }
                    },
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}

/// Ghost input field - no background, only bottom stroke.
class _GhostTextField extends ConsumerWidget {
  const _GhostTextField({
    required this.controller,
    this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final flavorConfig = ref.watch(flavorConfigProvider);
    final brandConfig = flavorConfig.values.brandConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textStyles.h2.copyWith(
              color: colors.secondaryTextColor,
              fontSize: 14,
              fontFamily: brandConfig.fontFamily,
              letterSpacing: 1.5,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: textStyles.body.copyWith(
            color: colors.primaryTextColor,
            fontFamily: brandConfig.fontFamily,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textStyles.body.copyWith(
              color: colors.hintTextColor.withValues(alpha: 0.6),
              fontFamily: brandConfig.fontFamily,
            ),
            // Ghost input: no background, only bottom border
            filled: false,
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colors.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colors.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colors.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colors.errorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colors.errorColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.only(bottom: 8),
          ),
        ),
      ],
    );
  }
}

/// Close button widget - very thin Close icon, top-right, 50% opacity.
class _CloseButton extends ConsumerWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;

    return IconButton(
      icon: Icon(
        Icons.close,
        color: colors.primaryColor.withValues(alpha: 0.5), // 50% opacity
        size: 18, // Very thin icon
      ),
      onPressed: onClose,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 18,
    );
  }
}

/// Brand logo widget.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.logoPath});

  final String logoPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logoPath,
      height: 60,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}

/// Google Sign In button - Solid Gold Bar with vertical gradient and high-contrast deep black text.
class _GoogleSignInButton extends ConsumerWidget {
  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final textStyles = context.appTextStyles;
    final flavorConfig = ref.watch(flavorConfigProvider);
    final brandConfig = flavorConfig.values.brandConfig;

    // Clean rectangular border radius (12px)
    const borderRadius = 12.0;

    // Solid Gold Bar: Vertical LinearGradient with primary gold tones
    // Create a vertical gradient from lighter to slightly darker gold for depth
    final goldTop = colors.primaryColor;
    final goldBottom =
        Color.lerp(
          colors.primaryColor,
          Colors.black,
          0.15,
        )!; // Slightly darker at bottom for premium solid gold bar effect

    // Text color: colors.secondary (High-Contrast Deep Black) to pop
    final textColor = colors.secondaryColor;

    return SizedBox(
      width: double.infinity,
      height: sizes.buttonHeightBig,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              // Solid Gold Bar: Vertical LinearGradient with primary gold tones
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [goldTop, goldBottom],
              ),
            ),
            child: Center(
              child:
                  isLoading
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.g_mobiledata,
                            color: textColor,
                            size: 24,
                          ),
                          Gap(sizes.paddingMedium),
                          Text(
                            context.l10n.continueWithGoogle,
                            style: textStyles.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor, // High-Contrast Deep Black
                              fontFamily: brandConfig.fontFamily,
                              letterSpacing: 1.5,
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

/// Premium Save button - metallic gold appearance with inner glow.
class _PremiumSaveButton extends ConsumerWidget {
  const _PremiumSaveButton({
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final textStyles = context.appTextStyles;
    final flavorConfig = ref.watch(flavorConfigProvider);
    final brandConfig = flavorConfig.values.brandConfig;

    return SizedBox(
      width: double.infinity,
      height: sizes.buttonHeightBig,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // High contrast metallic gradient - gold-like appearance
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryColor,
                  colors.primaryColor.withValues(alpha: 0.9),
                ],
              ),
              // Inner glow effect
              boxShadow: [
                BoxShadow(
                  color: colors.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: colors.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Center(
              child:
                  isLoading
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.secondaryColor,
                          ),
                        ),
                      )
                      : Text(
                        context.l10n.save,
                        style: textStyles.button.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.secondaryColor,
                          fontFamily: brandConfig.fontFamily,
                          letterSpacing: 1.5,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error message widget.
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: context.appColors.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        border: Border.all(
          color: context.appColors.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: context.appColors.errorColor,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
