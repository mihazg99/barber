import 'package:barber/features/auth/presentation/pages/auth_page.dart';
import 'package:barber/features/onboarding/application/onboarding_notifier.dart';
import 'package:barber/features/onboarding/application/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io';
import 'package:barber/core/config/app_brand_config.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';

class VendorOnboardingPage extends HookConsumerWidget {
  const VendorOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Listen to authentication state
    ref.listen(isAuthenticatedProvider, (prev, next) {
      if (next.valueOrNull == true) {
        final currentSteps = ref.read(onboardingNotifierProvider).value;
        final currentStep = currentSteps?.currentStep;

        if (currentStep == OnboardingStep.accountCreation) {
          final isComplete = ref.read(isProfileCompleteProvider);
          final notifier = ref.read(onboardingNotifierProvider.notifier);

          if (!isComplete) {
            notifier.nextStep(); // To ProfileSetup
          } else {
            // Profile is complete, check if we need to create brand
            notifier.goToStep(OnboardingStep.brandCreation);
          }
        }
      }
    });

    // separate verify for profile completion
    ref.listen(isProfileCompleteProvider, (prev, next) {
      final currentSteps = ref.read(onboardingNotifierProvider).value;
      final currentStep = currentSteps?.currentStep;

      if (next && currentStep == OnboardingStep.profileSetup) {
        ref
            .read(onboardingNotifierProvider.notifier)
            .nextStep(); // To BrandCreation
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: state.when(
        data: (data) {
          final selectedColors = data.generatedThemes?[data.selectedTheme];

          return Row(
            children: [
              // Left Side: Form
              Expanded(
                flex: 5,
                child: _FormSection(
                  currentStep: data.currentStep,
                  brandData: data.brandData,
                  isUploading: data.isUploading,
                  generatedThemes: data.generatedThemes,
                  selectedTheme: data.selectedTheme,
                ),
              ),
              if (isDesktop)
                Expanded(
                  flex: 4,
                  child: _LivePreviewSection(
                    brandData: data.brandData,
                    colors: selectedColors,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _FormSection extends HookConsumerWidget {
  final OnboardingStep currentStep;
  final BrandData brandData;
  final bool isUploading;
  final Map<ThemeOption, AppBrandColors>? generatedThemes;
  final ThemeOption selectedTheme;

  const _FormSection({
    required this.currentStep,
    required this.brandData,
    required this.isUploading,
    required this.generatedThemes,
    required this.selectedTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          const SizedBox(height: 48),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _StepContent(
                currentStep: currentStep,
                brandData: brandData,
                isUploading: isUploading,
                generatedThemes: generatedThemes,
                selectedTheme: selectedTheme,
              ),
            ),
          ),
          _NavigationButtons(currentStep: currentStep),
        ],
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  final OnboardingStep currentStep;
  final BrandData brandData;
  final bool isUploading;
  final Map<ThemeOption, AppBrandColors>? generatedThemes;
  final ThemeOption selectedTheme;

  const _StepContent({
    required this.currentStep,
    required this.brandData,
    required this.isUploading,
    required this.generatedThemes,
    required this.selectedTheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case OnboardingStep.brandDiscovery:
        return const _BrandDiscoveryStep();
      case OnboardingStep.magicBranding:
        return _MagicBrandingStep(
          isUploading: isUploading,
          generatedThemes: generatedThemes,
          selectedTheme: selectedTheme,
        );
      case OnboardingStep.businessSetup:
        return const _BusinessSetupStep();
      case OnboardingStep.accountCreation:
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: AuthPage(),
              ),
            ),
          ),
        );
      case OnboardingStep.profileSetup:
        return const _ProfileSetupStep();
      case OnboardingStep.brandCreation:
        return const _BrandCreationStep();
    }
  }
}

// ... existing classes ...

class _BrandCreationStep extends HookConsumerWidget {
  const _BrandCreationStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = useState('Initializing...');
    final error = useState<String?>(null);
    final hasStarted = useState(false);

    useEffect(() {
      if (hasStarted.value) return;
      hasStarted.value = true;

      Future<void> createBrand() async {
        try {
          status.value = 'Creating your brand environment...';

          final state = ref.read(onboardingNotifierProvider).value;
          final user = ref.read(currentUserProvider).valueOrNull;

          if (state == null || user == null) {
            throw Exception('State or User is missing');
          }

          final brandId = const Uuid().v4();
          final brandRef = FirebaseStorage.instance.ref().child(
            'brands/$brandId/logo.png',
          );

          String logoUrl = 'https://placehold.co/400';

          // Upload Logo if exists
          if (state.brandData.logoPath != null &&
              state.brandData.logoPath!.isNotEmpty) {
            status.value = 'Uploading brand assets...';
            try {
              if (kIsWeb) {
                // For web, if it's a blob URL, we might need a way to fetch it.
                // Simplification: Skip or use placeholder for now as accessing blob from path string is tricky without original XFile or fetching.
                // However, we can use the stored bytes if we had them.
                // We will skip for this MVP step to avoid http dependency if not present.
              } else {
                await brandRef.putFile(File(state.brandData.logoPath!));
                logoUrl = await brandRef.getDownloadURL();
              }
            } catch (e) {
              debugPrint('Logo upload failed: $e');
              // Continue with placeholder
            }
          }

          status.value = 'Configuring brand settings...';

          final colors = state.generatedThemes?[state.selectedTheme];

          final brand = BrandEntity(
            brandId: brandId,
            name:
                state.brandData.salonName.isEmpty
                    ? 'My Salon'
                    : state.brandData.salonName,
            tag: state.brandData.tag.isNotEmpty ? state.brandData.tag : null,
            isMultiLocation: false, // Default
            primaryColor: colors?.primary.toHex() ?? '#000000',
            logoUrl: logoUrl,
            contactEmail:
                FirebaseAuth.instance.currentUser?.email ?? '', // Fallback
            slotInterval: 30, // Default
            bufferTime: 5,
            themeColors: {
              'primary': colors?.primary.toHex() ?? '#000000',
              'background': colors?.background.toHex() ?? '#ffffff',
              'secondary': colors?.secondary.toHex() ?? '#cccccc',
            },
            currency: 'EUR',
            fontFamily: 'Inter',
            locale: 'en',
          );

          // Save Brand
          final brandRepo = ref.read(brandRepositoryProvider);
          await brandRepo.set(brand);

          status.value = 'Finalizing your account...';

          // Update User
          final userRepo = ref.read(userRepositoryProvider);
          final updatedUser = user.copyWith(
            brandId: brandId,
            role: UserRole.superadmin,
          );
          await userRepo.set(updatedUser);

          status.value = 'All done! Redirecting...';
          await Future.delayed(const Duration(seconds: 1));

          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          }
        } catch (e) {
          error.value = 'Failed to create brand: $e';
          status.value = 'Error occurred.';
        }
      }

      createBrand();
      return null;
    }, []);

    if (error.value != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(error.value!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                hasStarted.value = false; // Retry
                error.value = null;
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            status.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

extension HexColor on Color {
  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${((a * 255).round().toRadixString(16)).padLeft(2, '0')}'
      '${((r * 255).round().toRadixString(16)).padLeft(2, '0')}'
      '${((g * 255).round().toRadixString(16)).padLeft(2, '0')}'
      '${((b * 255).round().toRadixString(16)).padLeft(2, '0')}';
}

class _ProfileSetupStep extends HookConsumerWidget {
  const _ProfileSetupStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final nameController = useTextEditingController(text: user?.fullName);
    final phoneController = useTextEditingController(text: user?.phone);
    final isLoading = useState(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Almost there.',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please complete your profile to continue.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 48),
        _StyledTextField(
          label: 'Full Name',
          controller: nameController,
          onChanged: (_) {},
        ),
        const SizedBox(height: 24),
        _StyledTextField(
          label: 'Phone Number',
          controller: phoneController,
          onChanged: (_) {},
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                isLoading.value
                    ? null
                    : () async {
                      if (user == null) return;
                      isLoading.value = true;
                      try {
                        final repo = ref.read(userRepositoryProvider);
                        final updated = user.copyWith(
                          fullName: nameController.text,
                          phone: phoneController.text,
                        );
                        await repo.set(updated);

                        // Explicitly move to next step to ensure navigation happens immediately
                        if (context.mounted) {
                          ref
                              .read(onboardingNotifierProvider.notifier)
                              .goToStep(OnboardingStep.brandCreation);
                        }
                      } catch (e) {
                        debugPrint('Profile update failed: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update profile: $e'),
                            ),
                          );
                        }
                      } finally {
                        isLoading.value = false;
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text(
                      'Complete Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Placeholder for App Logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'STYL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _BrandDiscoveryStep extends HookConsumerWidget {
  const _BrandDiscoveryStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider).value;
    final brandData = state?.brandData;

    final nameController = useTextEditingController(
      text: brandData?.salonName,
    );
    final industryController = useTextEditingController(
      text: brandData?.industry,
    );
    final tagController = useTextEditingController(
      text: brandData?.tag,
    );

    // Sync controller with state if changed externally (or formatted)
    // But be careful not to break cursor position on every rebuild
    useEffect(() {
      if (brandData?.tag != null && tagController.text != brandData!.tag) {
        tagController.text = brandData.tag;
      }
      return null;
    }, [brandData?.tag]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Tell us about your brand.',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We will magically generate your app based on your details.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 48),
        _StyledTextField(
          label: 'Salon Name',
          controller: nameController,
          onChanged:
              (val) => ref
                  .read(onboardingNotifierProvider.notifier)
                  .updateBrandDiscovery(salonName: val),
        ),
        const SizedBox(height: 24),

        // TAG INPUT
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brand Tag (Handle)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagController,
              onChanged: (val) {
                ref.read(onboardingNotifierProvider.notifier).updateTag(val);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                prefixText: '@',
                prefixStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
                hintText: 'brand-name',
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: _buildTagSuffix(state),
              ),
            ),
            if (state?.isTagAvailable == false &&
                !state!.isCheckingTag &&
                (state.brandData.tag.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4),
                child: Text(
                  'That tag is already taken.',
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),
        _StyledTextField(
          label: 'Industry (e.g. Barber, Spa, Nails)',
          controller: industryController,
          onChanged:
              (val) => ref
                  .read(onboardingNotifierProvider.notifier)
                  .updateBrandDiscovery(industry: val),
        ),
      ],
    );
  }

  Widget? _buildTagSuffix(OnboardingState? state) {
    if (state == null || state.brandData.tag.isEmpty) return null;

    if (state.isCheckingTag) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (state.isTagAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.greenAccent);
    }

    if (state.isTagAvailable == false) {
      return const Icon(Icons.error, color: Colors.redAccent);
    }

    return null;
  }
}

class _StyledTextField extends HookWidget {
  final String label;
  final TextEditingController controller;
  final Function(String) onChanged;

  const _StyledTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _MagicBrandingStep extends HookConsumerWidget {
  final bool isUploading;
  final Map<ThemeOption, AppBrandColors>? generatedThemes;
  final ThemeOption selectedTheme;

  const _MagicBrandingStep({
    required this.isUploading,
    required this.generatedThemes,
    required this.selectedTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Add your logo.',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Watch as we extract your colors and apply them instantly.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 48),
        _LogoUploader(
          isUploading: isUploading,
          onLogoPicked: (path, provider) {
            ref
                .read(onboardingNotifierProvider.notifier)
                .uploadLogo(path, provider);
          },
        ),
        if (generatedThemes != null) ...[
          const SizedBox(height: 32),
          const Text(
            'Choose your style:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ThemeOptionCard(
                title: 'Vibrant',
                subtitle: 'Bold & Energetic',
                isSelected: selectedTheme == ThemeOption.vibrant,
                colors: generatedThemes![ThemeOption.vibrant]!,
                onTap:
                    () => ref
                        .read(onboardingNotifierProvider.notifier)
                        .selectTheme(ThemeOption.vibrant),
              ),
              const SizedBox(width: 12),
              _ThemeOptionCard(
                title: 'Soft',
                subtitle: 'Elegant & Calm',
                isSelected: selectedTheme == ThemeOption.soft,
                colors: generatedThemes![ThemeOption.soft]!,
                onTap:
                    () => ref
                        .read(onboardingNotifierProvider.notifier)
                        .selectTheme(ThemeOption.soft),
              ),
              const SizedBox(width: 12),
              _ThemeOptionCard(
                title: 'Contrast',
                subtitle: 'Clean & Sharp',
                isSelected: selectedTheme == ThemeOption.contrast,
                colors: generatedThemes![ThemeOption.contrast]!,
                onTap:
                    () => ref
                        .read(onboardingNotifierProvider.notifier)
                        .selectTheme(ThemeOption.contrast),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoUploader extends HookWidget {
  final bool isUploading;
  final Function(String, ImageProvider) onLogoPicked;

  const _LogoUploader({required this.isUploading, required this.onLogoPicked});

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (image != null) {
            // For web we might want to use bytes, for now simple path/provider
            // On web path is a blob url usually
            final provider =
                isKWeb ? NetworkImage(image.path) : FileImage(File(image.path));
            // cast to ImageProvider
            onLogoPicked(image.path, provider as ImageProvider);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                isHovered.value
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered.value ? Colors.blueAccent : Colors.white24,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child:
              isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color:
                            isHovered.value
                                ? Colors.blueAccent
                                : Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Click to upload logo',
                        style: TextStyle(
                          color:
                              isHovered.value
                                  ? Colors.blueAccent
                                  : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SVG, PNG, JPG (Max 5MB)',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // Helper to detect web since kIsWeb is const and might not be importable directly if foundations is missing
  bool get isKWeb => kIsWeb;
}

class _BusinessSetupStep extends HookConsumerWidget {
  const _BusinessSetupStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Powers, activate.',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enable powerful integrations to automate your business.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 48),
        _IntegrationCard(
          title: 'Stripe',
          description: 'Enable no-show protection and secure payments.',
          icon: Icons.payment,
          color: const Color(0xFF635BFF),
        ),
        const SizedBox(height: 16),
        _IntegrationCard(
          title: 'Solo.hr API',
          description: 'Automated invoicing for Croatian businesses.',
          icon: Icons.receipt_long,
          color: const Color(0xFF00C853),
        ),
      ],
    );
  }
}

class _IntegrationCard extends HookWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _IntegrationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = useState(false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled.value ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled.value,
            onChanged: (val) => enabled.value = val,
            // ignore: deprecated_member_use
            activeColor: color,
          ),
        ],
      ),
    );
  }
}

class _NavigationButtons extends HookConsumerWidget {
  final OnboardingStep currentStep;

  const _NavigationButtons({required this.currentStep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentStep == OnboardingStep.accountCreation ||
        currentStep == OnboardingStep.profileSetup ||
        currentStep == OnboardingStep.brandCreation) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentStep != OnboardingStep.brandDiscovery)
          TextButton(
            onPressed:
                () =>
                    ref
                        .read(onboardingNotifierProvider.notifier)
                        .previousStep(),
            child: const Text('Back', style: TextStyle(color: Colors.white54)),
          )
        else
          const SizedBox(),
        FloatingActionButton.extended(
          onPressed:
              () => ref.read(onboardingNotifierProvider.notifier).nextStep(),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          label: Row(
            children: [
              Text(
                currentStep == OnboardingStep.businessSetup
                    ? 'Continue'
                    : 'Continue',
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final AppBrandColors colors;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePreviewSection extends HookWidget {
  final BrandData brandData;
  final AppBrandColors? colors;

  const _LivePreviewSection({
    required this.brandData,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors dynamically or fallback to defaults if no colors passed yet
    // Default fallback to "Barber" dark theme
    final c =
        colors ??
        const AppBrandColors(
          primary: Color(0xFF6B63FF),
          secondary: Color(0xFF2A2F4A),
          background: Color(0xFF1E2235),
          navigationBackground: Color(0xFF1A1D2E),
          primaryText: Colors.white,
          secondaryText: Color(0xFFD1D5E0),
          captionText: Color(0xFF94A3B8),
          primaryWhite: Colors.white,
          hintText: Color(0xFFA6A9C8),
          menuBackground: Color(0xFF252A45),
          border: Color(0xFF393E5B),
          error: Color(0xFFB00020),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: const DecorationImage(
          image: AssetImage('assets/images/stars_bg.png'),
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          width: 375,
          height: 812,
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF2D3748), width: 8),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.3),
                blurRadius: 100,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Scaffold(
              backgroundColor: c.background,
              body: Column(
                children: [
                  // Mock Status Bar
                  Container(
                    height: 44,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '9:41',
                          style: TextStyle(
                            color: c.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 14,
                              color: c.primaryText,
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.wifi, size: 14, color: c.primaryText),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.battery_full,
                              size: 14,
                              color: c.primaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  brandData.salonName.isEmpty
                                      ? 'Your Brand'
                                      : brandData.salonName,
                                  style: TextStyle(
                                    color: c.primaryText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (brandData.logoPath != null)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image:
                                          kIsWeb
                                              ? NetworkImage(
                                                brandData.logoPath!,
                                              )
                                              : FileImage(
                                                    File(brandData.logoPath!),
                                                  )
                                                  as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.settings_outlined,
                                  color: c.primaryText,
                                  size: 24,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Loyalty Card Mock
                          Container(
                            height: 180,
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  c.primary,
                                  c.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Chip
                                    Container(
                                      width: 36,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37),
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD4AF37),
                                            Color(0xFFF1C40F),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                    // Title
                                    Text(
                                      'LOYALTY CARD',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '0 PTS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'MEMBER',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_2,
                                        size: 24,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Upcoming Booking Title
                          Text(
                            'UPCOMING',
                            style: TextStyle(
                              color: c.captionText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Empty state for booking
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: c.menuBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.border),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: c.secondaryText,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No upcoming appointments',
                                    style: TextStyle(
                                      color: c.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Services Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'POPULAR SERVICES',
                                style: TextStyle(
                                  color: c.captionText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'View all',
                                style: TextStyle(
                                  color: c.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Horizontal Services List
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _MockServiceCard(
                                  title: 'Precision Cut',
                                  price: '\$35',
                                  duration: '45min',
                                  colors: c,
                                ),
                                const SizedBox(width: 12),
                                _MockServiceCard(
                                  title: 'Beard Trim',
                                  price: '\$25',
                                  duration: '30min',
                                  colors: c,
                                ),
                                const SizedBox(width: 12),
                                _MockServiceCard(
                                  title: 'Full Service',
                                  price: '\$55',
                                  duration: '1h 15min',
                                  colors: c,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Nav Bar Mock
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: c.navigationBackground,
                      border: Border(
                        top: BorderSide(color: c.border, width: 1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _NavBarIcon(
                            icon: Icons.home_filled,
                            label: 'Home',
                            isActive: true,
                            activeColor: c.primary,
                            inactiveColor: c.secondaryText,
                          ),
                          _NavBarIcon(
                            icon: Icons.calendar_month_outlined,
                            label: 'Book',
                            isActive: false,
                            activeColor: c.primary,
                            inactiveColor: c.secondaryText,
                          ),
                          _NavBarIcon(
                            icon: Icons.person_outline,
                            label: 'Profile',
                            isActive: false,
                            activeColor: c.primary,
                            inactiveColor: c.secondaryText,
                          ),
                        ],
                      ),
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

class _MockServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final String duration;
  final AppBrandColors colors;

  const _MockServiceCard({
    required this.title,
    required this.price,
    required this.duration,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.menuBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: colors.primary, // Using primary for price for pop
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                duration,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Book',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 10, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const _NavBarIcon({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
