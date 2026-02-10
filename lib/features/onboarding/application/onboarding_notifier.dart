import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/core/config/app_brand_config.dart';
import 'package:barber/features/brand/di.dart';
import 'onboarding_state.dart';

class OnboardingNotifier extends AutoDisposeAsyncNotifier<OnboardingState> {
  Timer? _debounceTimer;

  @override
  FutureOr<OnboardingState> build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const OnboardingState();
  }

  void updateBrandDiscovery({String? salonName, String? industry}) {
    state = AsyncValue.data(
      state.value!.copyWith(
        brandData: state.value!.brandData.copyWith(
          salonName: salonName,
          industry: industry,
        ),
      ),
    );
  }

  void updateTag(String tag) {
    // 1. Update local state immediately
    // Format: lowercase, replace spaces with dashes
    final formattedTag = tag.trim().toLowerCase().replaceAll(' ', '-');

    if (formattedTag == state.value?.brandData.tag) return;

    state = AsyncValue.data(
      state.value!.copyWith(
        brandData: state.value!.brandData.copyWith(tag: formattedTag),
        isTagAvailable: null, // Reset availability
        isCheckingTag: true,
      ),
    );

    // 2. Debounce check
    _debounceTimer?.cancel();

    if (formattedTag.isEmpty) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isCheckingTag: false,
          isTagAvailable: null,
        ),
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkTagAvailability(formattedTag);
    });
  }

  Future<void> _checkTagAvailability(String tag) async {
    // If tag was cleared while waiting
    if (tag.isEmpty) return;

    final repo = ref.read(brandRepositoryProvider);
    final result = await repo.isTagAvailable(tag);

    result.fold(
      (failure) {
        // Handle error (maybe assume false or show error?)
        // For now, let's set it to null or false
        state = AsyncValue.data(
          state.value!.copyWith(isCheckingTag: false, isTagAvailable: false),
        );
      },
      (isAvailable) {
        // Ensure the tag hasn't changed since we started the check
        if (state.value?.brandData.tag == tag) {
          state = AsyncValue.data(
            state.value!.copyWith(
              isCheckingTag: false,
              isTagAvailable: isAvailable,
            ),
          );
        }
      },
    );
  }

  Future<void> uploadLogo(String logoPath, ImageProvider imageProvider) async {
    state = AsyncValue.data(state.value!.copyWith(isUploading: true));

    try {
      // Simulate upload delay or processing
      await Future.delayed(const Duration(milliseconds: 800));

      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      final themes = _generateThemes(palette);

      state = AsyncValue.data(
        state.value!.copyWith(
          brandData: state.value!.brandData.copyWith(logoPath: logoPath),
          extractedPalette: palette,
          generatedThemes: themes,
          isUploading: false,
          currentStep: OnboardingStep.magicBranding,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void selectTheme(ThemeOption option) {
    state = AsyncValue.data(state.value!.copyWith(selectedTheme: option));
  }

  void nextStep() {
    final current = state.value!.currentStep;
    final nextIndex = current.index + 1;
    if (nextIndex < OnboardingStep.values.length) {
      state = AsyncValue.data(
        state.value!.copyWith(currentStep: OnboardingStep.values[nextIndex]),
      );
    }
  }

  void previousStep() {
    final current = state.value!.currentStep;
    final prevIndex = current.index - 1;
    if (prevIndex >= 0) {
      state = AsyncValue.data(
        state.value!.copyWith(currentStep: OnboardingStep.values[prevIndex]),
      );
    }
  }

  void goToStep(OnboardingStep step) {
    state = AsyncValue.data(state.value!.copyWith(currentStep: step));
  }

  Map<ThemeOption, AppBrandColors> _generateThemes(PaletteGenerator palette) {
    // 1. Extract base color (default to Indigo/Blue if none found)
    // We prefer Vibrant -> Light Vibrant -> Dark Vibrant -> Dominant
    final baseColor =
        palette.vibrantColor?.color ??
        palette.lightVibrantColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.dominantColor?.color ??
        const Color(0xFF6366F1);

    return {
      ThemeOption.vibrant: _createVibrantTheme(baseColor),
      ThemeOption.soft: _createSoftTheme(baseColor),
      ThemeOption.contrast: _createContrastTheme(baseColor),
    };
  }

  AppBrandColors _createVibrantTheme(Color brandColor) {
    // Vibrant:
    // Primary: Brand Color
    // Background: Dark Slate (#020617)
    // Surface: Dark Blue/Slate (#0F172A)
    return AppBrandColors(
      primary: brandColor,
      secondary: _darken(brandColor, 0.2),
      background: const Color(0xFF020617),
      navigationBackground: const Color(0xFF0F172A),
      primaryText: const Color(0xFFF8FAFC),
      secondaryText: const Color(0xFF94A3B8),
      captionText: const Color(0xFF64748B),
      primaryWhite: Colors.white,
      hintText: const Color(0xFF475569),
      menuBackground: const Color(0xFF0F172A),
      border: const Color(0xFF1E293B),
      error: const Color(0xFFEF4444),
    );
  }

  AppBrandColors _createSoftTheme(Color brandColor) {
    // Soft:
    // Primary: Desaturated Brand Color
    // Background: Softer Dark (#1E2235 - from defaults)
    final softPrimary =
        HSLColor.fromColor(brandColor)
            .withSaturation(0.6) // Reduced saturation
            .toColor();

    return AppBrandColors(
      primary: softPrimary,
      secondary: _darken(softPrimary, 0.3),
      background: const Color(0xFF1E2235), // Softer background
      navigationBackground: const Color(0xFF252A45),
      primaryText: const Color(0xFFE2E8F0),
      secondaryText: const Color(0xFF94A3B8), // Muted text
      captionText: const Color(0xFF64748B),
      primaryWhite: Colors.white,
      hintText: const Color(0xFF475569),
      menuBackground: const Color(0xFF252A45),
      border: const Color(0xFF2A2F4A),
      error: const Color(0xFFEF4444),
    );
  }

  AppBrandColors _createContrastTheme(Color brandColor) {
    // Contrast:
    // Primary: White or Black (Monochrome feel) with subtle accent
    // Background: Pure Black (#000000)
    return AppBrandColors(
      primary: Colors.white, // High contrast
      secondary: const Color(0xFF171717),
      background: Colors.black,
      navigationBackground: const Color(0xFF111111),
      primaryText: Colors.white,
      secondaryText: const Color(0xFFA3A3A3),
      captionText: const Color(0xFF737373),
      primaryWhite: Colors.white,
      hintText: const Color(0xFF525252),
      menuBackground: const Color(0xFF111111),
      border: const Color(0xFF262626),
      error: const Color(0xFFEF4444),
    );
  }

  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

final onboardingNotifierProvider =
    AsyncNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
