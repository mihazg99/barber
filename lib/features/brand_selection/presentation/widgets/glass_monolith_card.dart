import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:barber/features/brand/domain/entities/brand_entity.dart';

/// Design constants for the Glass Monolith
class _GlassDesign {
  static const double width = 280.0;
  static const double height = 360.0;
  static const double neutralRadius = 32.0;
  static const double morphedRadius = 24.0;
  static const double logoSize = 120.0;
}

/// True glass monolith using BackdropFilter for transparency
class GlassMonolithCard extends HookWidget {
  const GlassMonolithCard({
    required this.brand,
    required this.morphProgress,
    required this.scale,
    this.onTap,
    super.key,
  });

  final BrandEntity? brand;
  final double morphProgress;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Animate border radius
    final borderRadius = lerpDouble(
      _GlassDesign.neutralRadius,
      _GlassDesign.morphedRadius,
      morphProgress,
    )!;

    // Parse brand color
    Color? brandColor;
    if (brand != null) {
      brandColor = _hexToColor(brand!.primaryColor);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _GlassDesign.width,
          height: _GlassDesign.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow (centered using Stack alignment)
              if (brand != null && morphProgress > 0)
                _PulsingGlow(
                  color: brandColor!,
                  intensity: morphProgress * 0.5,
                  width: _GlassDesign.width,
                  height: _GlassDesign.height,
                  borderRadius: borderRadius,
                ),

              // Glass card with BackdropFilter
              Container(
                width: _GlassDesign.width,
                height: _GlassDesign.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    // Depth shadows
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
                      // BackdropFilter for glass effect
                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 20.0,
                          sigmaY: 20.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            // Transparent glass with subtle brightening
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.10),
                                Colors.white.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Gradient border for light-hitting-edges effect
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.transparent,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.02),
                              brandColor?.withValues(alpha: 0.08) ??
                                  const Color(0xFF1E293B).withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius - 1.5),
                            color: Colors.transparent,
                          ),
                        ),
                      ),

                      // Brand logo or placeholder
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

                      // Pulse effect in neutral state
                      if (brand == null) _PulseEffect(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return const Color(0xFF6B63FF);
  }
}

/// Pulsing glow effect using CustomPaint, centered via Stack
class _PulsingGlow extends HookWidget {
  const _PulsingGlow({
    required this.color,
    required this.intensity,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final Color color;
  final double intensity;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Pulsing animation
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    final pulseValue = useAnimation(controller);
    final glowIntensity = intensity * (0.5 + pulseValue * 0.5);

    return CustomPaint(
      painter: _GlowPainter(
        color: color,
        intensity: glowIntensity,
        borderRadius: borderRadius,
      ),
      size: Size(width, height),
    );
  }
}

/// Custom painter for the glow effect
class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.color,
    required this.intensity,
    required this.borderRadius,
  });

  final Color color;
  final double intensity;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Outer glow
    final paint = Paint()
      ..color = color.withValues(alpha: intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * intensity);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.color != color;
  }
}

/// Brand logo widget
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
      scale: 0.8 + (morphProgress * 0.2),
      child: Container(
        width: _GlassDesign.logoSize,
        height: _GlassDesign.logoSize,
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
