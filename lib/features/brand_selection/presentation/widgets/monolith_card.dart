import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:barber/features/brand/domain/entities/brand_entity.dart';

/// Design constants for the Sapphire Architect style
class _MonolithDesign {
  static const double width = 280.0;
  static const double height = 360.0;
  static const double neutralRadius = 32.0;
  static const double morphedRadius = 24.0;
  static const double logoSize = 120.0;
}

/// Glassmorphic card that morphs when brand is selected.
/// Central element of the portal experience.
class MonolithCard extends HookWidget {
  const MonolithCard({
    required this.brand,
    required this.morphProgress,
    required this.scale,
    this.onTap,
    super.key,
  });

  final BrandEntity? brand;
  final double morphProgress; // 0.0 to 1.0
  final double scale; // Scale animation value
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Animate border radius from neutral to morphed
    final borderRadius = lerpDouble(
      _MonolithDesign.neutralRadius,
      _MonolithDesign.morphedRadius,
      morphProgress,
    )!;

    // Calculate glow intensity based on morph progress
    final glowIntensity = morphProgress * 0.5;

    // Parse brand color if available
    Color? brandColor;
    if (brand != null) {
      brandColor = _hexToColor(brand!.primaryColor);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _MonolithDesign.width,
          height: _MonolithDesign.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              // Outer glow that intensifies during morph
              if (glowIntensity > 0 && brandColor != null)
                BoxShadow(
                  color: brandColor.withValues(alpha: glowIntensity),
                  blurRadius: 40 * glowIntensity,
                  spreadRadius: 10 * glowIntensity,
                ),
              // Depth shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // Glassmorphic background with BackdropFilter - PREMIUM GLASS
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 32.0,
                    sigmaY: 32.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      // Increased white opacity for artificial glass effect
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        width: 1.5,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),

                // Edge highlights - "light hitting glass" effect (ENHANCED)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                        brandColor?.withValues(alpha: 0.10) ?? 
                            const Color(0xFF1E293B).withValues(alpha: 0.10),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),

                // Subtle inner glow for depth
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      // Top inner glow
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        blurRadius: 8,
                        spreadRadius: -4,
                        offset: const Offset(0, -3),
                        blurStyle: BlurStyle.outer,
                      ),
                      // Bottom inner glow
                      BoxShadow(
                        color: brandColor?.withValues(alpha: glowIntensity * 0.15) ??
                            Colors.white.withValues(alpha: 0.04),
                        blurRadius: 15,
                        spreadRadius: -8,
                        offset: const Offset(0, 3),
                        blurStyle: BlurStyle.outer,
                      ),
                    ],
                  ),
                ),

                // Content: Brand logo or placeholder
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: brand != null ? morphProgress : 0.0,
                    curve: Curves.easeOutExpo,
                    child: brand != null
                        ? _BrandLogo(
                            logoUrl: brand!.logoUrl,
                            brandName: brand!.name,
                            morphProgress: morphProgress,
                          )
                        : _PlaceholderIcon(),
                  ),
                ),

                // Subtle pulse effect in neutral state
                if (brand == null) _PulseEffect(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Parse hex color string to Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return const Color(0xFF6B63FF); // Fallback color
  }
}

/// Brand logo with scale animation
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({
    required this.logoUrl,
    required this.brandName,
    required this.morphProgress,
  });

  final String logoUrl;
  final String brandName;
  final double morphProgress;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8 + (morphProgress * 0.2), // Scale from 0.8 to 1.0
      child: Container(
        width: _MonolithDesign.logoSize,
        height: _MonolithDesign.logoSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: logoUrl.isNotEmpty
              ? Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.store,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                )
              : Container(
                  color: Colors.white.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.store,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Placeholder icon for neutral state
class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.radio_button_unchecked,
      size: 80,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

/// Subtle pulse effect for neutral state
class _PulseEffect extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    final animation = useAnimation(controller);

    return Center(
      child: Container(
        width: 100 + (animation * 20),
        height: 100 + (animation * 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1 * (1 - animation)),
            width: 2,
          ),
        ),
      ),
    );
  }
}
