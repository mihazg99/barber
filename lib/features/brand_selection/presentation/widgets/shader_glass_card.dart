import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:barber/features/brand/domain/entities/brand_entity.dart';

/// Design constants matching the button's visual DNA
class _MonolithDesign {
  static const double width = 280.0;
  static const double height = 360.0;
  static const double neutralRadius = 32.0;
  static const double morphedRadius = 24.0;
  static const double logoSize = 120.0;
  static const double blurSigma = 28.0; // 25-30 range for crisp clarity
  static const double borderWidth = 1.2; // Precise specular border
}

/// Premium glass monolith matching button's visual DNA exactly
/// Crisp, transparent, and expensive-looking
class ShaderGlassCard extends HookWidget {
  const ShaderGlassCard({
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
    // Professional breathing animation - 3.5s cycle with sine curve
    final breatheController = useAnimationController(
      duration: const Duration(milliseconds: 3500),
    );

    // Smooth breathing curve (sine wave for natural feel)
    final breatheCurve = useMemoized(
      () => CurvedAnimation(
        parent: breatheController,
        curve: Curves.easeInOutSine,
      ),
      [breatheController],
    );

    // Start infinite breathing animation
    useEffect(() {
      breatheController.repeat(reverse: true);
      return null;
    }, [breatheController]);

    final breatheValue = useAnimation(breatheCurve);

    // Subtle scale: 1.0 to 1.015 (1.5% growth)
    final breatheScale = 1.0 + (breatheValue * 0.015);
    
    // Subtle glow intensity: 0.3 to 0.5
    final breatheGlow = 0.3 + (breatheValue * 0.2);

    // Animate border radius
    final borderRadius = ui.lerpDouble(
      _MonolithDesign.neutralRadius,
      _MonolithDesign.morphedRadius,
      morphProgress,
    )!;

    // Parse brand color
    final brandColor = brand != null 
        ? _hexToColor(brand!.primaryColor) 
        : const Color(0xFF6366F1);

    return Transform.scale(
      scale: scale * breatheScale, // Combine user scale with breathing
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _MonolithDesign.width,
          height: _MonolithDesign.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Depth shadows for floating effect (with breathing)
              Container(
                width: _MonolithDesign.width,
                height: _MonolithDesign.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0x66000000),
                        const Color(0x80000000),
                        breatheValue * 0.3,
                      )!,
                      blurRadius: 30 + (breatheValue * 5),
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0x33000000),
                        const Color(0x4D000000),
                        breatheValue * 0.3,
                      )!,
                      blurRadius: 60 + (breatheValue * 10),
                      offset: const Offset(0, 30),
                    ),
                  ],
                ),
              ),

              // Subtle ambient glow (always present, breathes with container)
              _AmbientGlow(
                intensity: breatheGlow * 0.15,
                borderRadius: borderRadius,
                color: brand == null 
                    ? const Color(0xFF6366F1)
                    : brandColor,
              ),

              // Pulsing brand glow (only during morph)
              if (brand != null && morphProgress > 0)
                _PulsingGlow(
                  color: brandColor,
                  intensity: morphProgress * 0.5,
                  borderRadius: borderRadius,
                ),

              // Main glass monolith (matching button DNA)
              ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: _MonolithDesign.blurSigma,
                    sigmaY: _MonolithDesign.blurSigma,
                  ),
                  child: Container(
                    width: _MonolithDesign.width,
                    height: _MonolithDesign.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      // Linear gradient fill (button DNA: 0.08 to 0.04)
                      // Slightly brighter during breathe
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            const Color(0x14FFFFFF),
                            const Color(0x1AFFFFFF),
                            breatheValue * 0.4,
                          )!,
                          Color.lerp(
                            const Color(0x0AFFFFFF),
                            const Color(0x10FFFFFF),
                            breatheValue * 0.4,
                          )!,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _SpecularBorderPainter(
                        borderRadius: borderRadius,
                        borderWidth: _MonolithDesign.borderWidth,
                        brandColor: brandColor,
                        morphProgress: morphProgress,
                        breatheIntensity: breatheValue,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing center effect (neutral state)
                          if (brand == null)
                            const _PulsingCenter(),
                          
                          // Brand content (logo or placeholder)
                          _BrandContent(
                            brand: brand,
                            morphProgress: morphProgress,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    return const Color(0xFF6366F1);
  }
}

/// Specular border painter with gradient (white 0.2 to transparent)
class _SpecularBorderPainter extends CustomPainter {
  const _SpecularBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.brandColor,
    required this.morphProgress,
    required this.breatheIntensity,
  });

  final double borderRadius;
  final double borderWidth;
  final Color brandColor;
  final double morphProgress;
  final double breatheIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Border gradient: white 0.2 at top-left to transparent at bottom-right
    // Intensifies slightly during breathing
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(
          const Color(0x33FFFFFF),
          const Color(0x40FFFFFF),
          breatheIntensity * 0.3,
        )!, // white 0.2 to 0.25
        Color.lerp(
          const Color(0x19FFFFFF),
          const Color(0x26FFFFFF),
          breatheIntensity * 0.3,
        )!, // white 0.1 to 0.15
        brandColor.withValues(
          alpha: 0.15 * morphProgress * (1.0 + breatheIntensity * 0.3),
        ), // brand hint
        const Color(0x00FFFFFF), // transparent
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularBorderPainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.brandColor != brandColor ||
        oldDelegate.breatheIntensity != breatheIntensity;
  }
}

/// Pulsing center effect for neutral state
class _PulsingCenter extends HookWidget {
  const _PulsingCenter();

  @override
  Widget build(BuildContext context) {
    // Smooth pulsing animation (4 second cycle for more subtle effect)
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 4000),
    );

    // Start the repeating animation (no reverse - restarts from beginning)
    useEffect(() {
      controller.repeat();
      return null;
    }, [controller]);

    final pulseValue = useAnimation(controller);

    return CustomPaint(
      painter: _CenterPulsePainter(
        pulseValue: pulseValue,
      ),
      size: const Size(_MonolithDesign.width, _MonolithDesign.height),
    );
  }
}

/// Painter for the center pulsing effect (only expands outward)
class _CenterPulsePainter extends CustomPainter {
  const _CenterPulsePainter({
    required this.pulseValue,
  });

  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Three concentric rings pulsing outward only
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.2; // Stagger the rings
      final adjustedPulse = (pulseValue + delay) % 1.0;
      
      // Only draw if pulse has started (avoid showing rings at start)
      if (adjustedPulse < 0.05) continue;
      
      // Radius grows from 50 to 120 (expands outward only)
      final radius = 50.0 + (adjustedPulse * 70.0);
      
      // Opacity: subtle fade (more gentle)
      // Use easeOut curve for smooth fade
      final fadeOut = 1.0 - (adjustedPulse * adjustedPulse); // Quadratic ease out
      final opacity = fadeOut * 0.08; // Max 0.08 opacity (subtle)
      
      // Only draw if visible
      if (opacity < 0.01) continue;
      
      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5; // Thinner stroke for subtlety

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CenterPulsePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

/// Pulsing glow effect for brand color during morph
class _PulsingGlow extends HookWidget {
  const _PulsingGlow({
    required this.color,
    required this.intensity,
    required this.borderRadius,
  });

  final Color color;
  final double intensity;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Pulsing animation (2 second cycle)
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
      size: const Size(_MonolithDesign.width, _MonolithDesign.height),
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

/// Ambient glow - subtle, always present, breathes with container
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.intensity,
    required this.borderRadius,
    required this.color,
  });

  final double intensity;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmbientGlowPainter(
        color: color,
        intensity: intensity,
        borderRadius: borderRadius,
      ),
      size: const Size(_MonolithDesign.width, _MonolithDesign.height),
    );
  }
}

/// Custom painter for ambient glow
class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({
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

    // Soft ambient glow - multiple layers for depth
    for (int i = 0; i < 3; i++) {
      final layerIntensity = intensity * (1.0 - i * 0.3);
      final blurRadius = 20.0 + (i * 15.0);
      
      final paint = Paint()
        ..color = color.withValues(alpha: layerIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.color != color;
  }
}

/// Brand content: logo or placeholder with smooth fade
class _BrandContent extends StatelessWidget {
  const _BrandContent({
    required this.brand,
    required this.morphProgress,
  });

  final BrandEntity? brand;
  final double morphProgress;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      opacity: brand != null ? morphProgress : 0.0,
      curve: Curves.easeOutExpo,
      child: brand != null
          ? _BrandLogo(
              logoUrl: brand!.logoUrl,
              brandName: brand!.name,
              morphProgress: morphProgress,
            )
          : const _PlaceholderIcon(),
    );
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
      scale: 0.8 + (morphProgress * 0.2),
      child: Container(
        width: _MonolithDesign.logoSize,
        height: _MonolithDesign.logoSize,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000), // 0.2 alpha
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: logoUrl.isNotEmpty
              ? Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0x1AFFFFFF), // 0.1 alpha
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0x1AFFFFFF), // 0.1 alpha
                    child: const Icon(
                      Icons.store,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                )
              : Container(
                  color: const Color(0x1AFFFFFF), // 0.1 alpha
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
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.radio_button_unchecked,
      size: 80,
      color: Color(0x4DFFFFFF), // white 0.3
    );
  }
}

// Removed _FallbackGlassCard - no longer needed with simple approach
