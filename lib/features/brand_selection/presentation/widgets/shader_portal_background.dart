import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Liquid Sapphire Background - Hook Architecture with 60/120Hz fluidity
/// Uses HookConsumerWidget for proper state management and frame-perfect animation
class ShaderPortalBackground extends HookConsumerWidget {
  const ShaderPortalBackground({
    required this.baseColor,
    required this.targetColor,
    required this.morphProgress,
    super.key,
  });

  final Color baseColor;
  final Color targetColor;
  final double morphProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load shader once and cache
    final shaderFuture = useMemoized(
      () => ui.FragmentProgram.fromAsset('shaders/background.frag'),
      [],
    );

    final shaderSnapshot = useFuture(shaderFuture);

    // Animation controller - 60 second natural seamless loop
    final animController = useAnimationController(
      duration: const Duration(seconds: 60), // Matches shader LOOP_DURATION
    )..repeat();

    // Force rebuild every frame for 60/120Hz fluidity
    final animatedTime = useAnimation(animController);

    if (!shaderSnapshot.hasData || shaderSnapshot.data == null) {
      // Premium sapphire fallback while loading
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFF0F172A), // Sapphire base
              const Color(0xFF0A0F1E), // Almost black
            ],
          ),
        ),
      );
    }

    return _ShaderBackground(
      shader: shaderSnapshot.data!.fragmentShader(),
      time: animatedTime * 60.0, // Direct 1:1 mapping for perfect seamless loop
    );
  }
}

/// Private shader background widget - renders the liquid sapphire effect
class _ShaderBackground extends StatelessWidget {
  const _ShaderBackground({
    required this.shader,
    required this.time,
  });

  final ui.FragmentShader shader;
  final double time;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LiquidSapphirePainter(
        shader: shader,
        time: time,
      ),
      size: Size.infinite,
    );
  }
}

/// Private painter for liquid sapphire effect
/// Handles shader uniform updates and rendering
class _LiquidSapphirePainter extends CustomPainter {
  _LiquidSapphirePainter({
    required this.shader,
    required this.time,
  });

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms in order: uSize (vec2), uTime (float)
    shader
      ..setFloat(0, size.width)   // uSize.x
      ..setFloat(1, size.height)  // uSize.y
      ..setFloat(2, time);        // uTime - seamless looping handled in shader

    // Use Paint with optimized settings for performance
    final paint = Paint()
      ..shader = shader
      ..isAntiAlias = false; // Disable AA for full-screen shader (performance boost)

    // Draw full-screen liquid sapphire background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LiquidSapphirePainter oldDelegate) {
    // Repaint every frame for smooth 60/120Hz animation
    return oldDelegate.time != time;
  }
  
  @override
  bool shouldRebuildSemantics(_LiquidSapphirePainter oldDelegate) => false;
}
