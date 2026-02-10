import 'package:equatable/equatable.dart';
import 'package:barber/core/config/app_brand_config.dart';
import 'package:palette_generator/palette_generator.dart';

enum OnboardingStep {
  brandDiscovery,
  magicBranding,
  businessSetup,
  accountCreation,
  profileSetup,
  brandCreation,
}

class BrandData extends Equatable {
  final String salonName;
  final String industry;
  final String? logoPath;
  final String tag;
  // We might store raw bytes or a file path depending on platform (web usually bytes/blob url)

  const BrandData({
    this.salonName = '',
    this.industry = '',
    this.logoPath,
    this.tag = '',
  });

  BrandData copyWith({
    String? salonName,
    String? industry,
    String? logoPath,
    String? tag,
  }) {
    return BrandData(
      salonName: salonName ?? this.salonName,
      industry: industry ?? this.industry,
      logoPath: logoPath ?? this.logoPath,
      tag: tag ?? this.tag,
    );
  }

  @override
  List<Object?> get props => [salonName, industry, logoPath, tag];
}

enum ThemeOption {
  vibrant,
  soft,
  contrast,
}

class OnboardingState extends Equatable {
  final OnboardingStep currentStep;
  final BrandData brandData;
  final PaletteGenerator? extractedPalette;
  final bool isUploading;
  final ThemeOption selectedTheme;
  // We store the generated colors for each option so we don't re-generating them constantly
  final Map<ThemeOption, AppBrandColors>? generatedThemes;

  final bool isCheckingTag;
  final bool?
  isTagAvailable; // null = not checked/empty, true = available, false = taken

  const OnboardingState({
    this.currentStep = OnboardingStep.brandDiscovery,
    this.brandData = const BrandData(),
    this.extractedPalette,
    this.isUploading = false,
    this.selectedTheme = ThemeOption.vibrant,
    this.generatedThemes,
    this.isCheckingTag = false,
    this.isTagAvailable,
  });

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    BrandData? brandData,
    PaletteGenerator? extractedPalette,
    bool? isUploading,
    ThemeOption? selectedTheme,
    Map<ThemeOption, AppBrandColors>? generatedThemes,
    bool? isCheckingTag,
    bool? isTagAvailable,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      brandData: brandData ?? this.brandData,
      extractedPalette: extractedPalette ?? this.extractedPalette,
      isUploading: isUploading ?? this.isUploading,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      generatedThemes: generatedThemes ?? this.generatedThemes,
      isCheckingTag: isCheckingTag ?? this.isCheckingTag,
      isTagAvailable: isTagAvailable ?? this.isTagAvailable,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    brandData,
    extractedPalette,
    isUploading,
    selectedTheme,
    generatedThemes,
    isCheckingTag,
    isTagAvailable,
  ];
}
