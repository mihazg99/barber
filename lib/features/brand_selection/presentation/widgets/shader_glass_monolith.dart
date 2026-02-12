import 'dart:ui' as ui;

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

/// Shader-based glass monolith with refraction and frosting
class ShaderGlassMonolith extends HookWidget {
  const ShaderGlassMonolith({
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
    // Load glass shader
    final shaderFuture = useMemoized(
      () => ui.FragmentProgram.fromAsset('shaders/glass.frag'),
      [],
    );

    final shaderSnapshot = useFuture(shaderFuture);

    // Animation for shader time uniform
    final ticker = useAnimationController(
      duration: const Duration(days: 1),
    )..repeat();

    final time = useAnimation(ticker);

    // Animate border radius
    final borderRadius = ui.lerpDouble(
      _GlassDesign.neutralRadius,
      _GlassDesign.morphedRadius,
      morphProgress,
    )!;

    // Parse brand color
    Color? brandColor;
    if (brand != null) {
      brandColor = _hexToColor(brand!.primaryColor);
    }

    // Calculate glow intensity
    final glowIntensity = morphProgress * 0.5;

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _GlassDesign.width,
          height: _GlassDesign.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              // Outer glow during morph
              if (glowIntensity > 0 && brandColor != null)
                BoxShadow(
                  color: brandColor.withValues(alpha: glowIntensity),
                  blurRadius: 40 * glowIntensity,
                  spreadRadius: 10 * glowIntensity,
                ),
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
                // Shader-based glass effect
                if (shaderSnapshot.hasData && shaderSnapshot.data != null)
                  CustomPaint(
                    painter: _GlassPainter(
                      shader: shaderSnapshot.data!.fragmentShader(),
                      time: time * 50,
                    ),
                    size: const Size(
                      _GlassDesign.width,
                      _GlassDesign.height,
                    ),
                  )
                else
                  // Fallback while loading
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(borderRadius),
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

/// Custom painter for glass shader
class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.shader,
    required this.time,
  });

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms
    shader
      ..setFloat(0, size.width)   // uSize.x
      ..setFloat(1, size.height)  // uSize.y
      ..setFloat(2, time);        // uTime

    // Note: uTexture (sampler2D) would be set differently
    // For now, shader will use a default or generate its own pattern

    final paint = Paint()..shader = shader;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) {
    return oldDelegate.time != time;
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

/// Subtle pulse effect
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
