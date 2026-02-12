import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated blob for the mesh background
class _AnimatedBlob {
  _AnimatedBlob({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.pulseSpeed,
  });

  final double baseX; // Base position (0.0 to 1.0)
  final double baseY;
  final double radius;
  final Color color;
  final double speedX; // Movement speed multipliers
  final double speedY;
  final double pulseSpeed;

  Offset getPosition(Size size, double time) {
    final dx = size.width * baseX + math.sin(time * speedX) * size.width * 0.2;
    final dy = size.height * baseY + math.cos(time * speedY) * size.height * 0.2;
    return Offset(dx, dy);
  }

  double getRadius(double time) {
    return radius * (1.0 + math.sin(time * pulseSpeed) * 0.3);
  }
}

/// CustomPainter that creates a living, breathing mesh gradient background.
/// Multiple animated blobs create depth and organic movement.
class FluidMeshPainter extends CustomPainter {
  FluidMeshPainter({
    required this.baseColor,
    required this.targetColor,
    required this.morphProgress,
    required this.time,
  }) {
    _initializeBlobs();
  }

  final Color baseColor;
  final Color targetColor;
  final double morphProgress;
  final double time;

  late final List<_AnimatedBlob> _blobs;

  void _initializeBlobs() {
    final currentColor = Color.lerp(baseColor, targetColor, morphProgress)!;
    
    // Create subtle variations of the base color (deep indigo/sapphire)
    final color1 = Color.lerp(currentColor, const Color(0xFF1E293B), 0.3)!;
    final color2 = Color.lerp(currentColor, const Color(0xFF334155), 0.5)!;
    final color3 = Color.lerp(currentColor, const Color(0xFF0F172A), 0.2)!;
    final color4 = Color.lerp(currentColor, const Color(0xFF1E3A8A), 0.4)!;

    _blobs = [
      // Large slow-moving blobs
      _AnimatedBlob(
        baseX: 0.2,
        baseY: 0.3,
        radius: 300,
        color: color1.withValues(alpha: 0.4),
        speedX: 0.3,
        speedY: 0.2,
        pulseSpeed: 0.5,
      ),
      _AnimatedBlob(
        baseX: 0.8,
        baseY: 0.7,
        radius: 350,
        color: color2.withValues(alpha: 0.35),
        speedX: 0.25,
        speedY: 0.35,
        pulseSpeed: 0.4,
      ),
      _AnimatedBlob(
        baseX: 0.5,
        baseY: 0.5,
        radius: 280,
        color: color3.withValues(alpha: 0.45),
        speedX: 0.2,
        speedY: 0.3,
        pulseSpeed: 0.6,
      ),
      // Medium blobs for detail
      _AnimatedBlob(
        baseX: 0.1,
        baseY: 0.8,
        radius: 200,
        color: color4.withValues(alpha: 0.3),
        speedX: 0.35,
        speedY: 0.25,
        pulseSpeed: 0.7,
      ),
      _AnimatedBlob(
        baseX: 0.9,
        baseY: 0.2,
        radius: 220,
        color: color1.withValues(alpha: 0.25),
        speedX: 0.28,
        speedY: 0.32,
        pulseSpeed: 0.55,
      ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Base solid color
    final baseColorInterpolated = Color.lerp(baseColor, targetColor, morphProgress)!;
    final basePaint = Paint()..color = baseColorInterpolated;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Draw each animated blob
    for (final blob in _blobs) {
      final center = blob.getPosition(size, time);
      final radius = blob.getRadius(time);

      // Create radial gradient for each blob
      final gradient = RadialGradient(
        colors: [
          blob.color,
          blob.color.withValues(alpha: blob.color.a * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..blendMode = BlendMode.screen; // Screen blend for lighter overlay

      canvas.drawCircle(center, radius, paint);
    }

    // Add a subtle overall gradient for depth
    final overlayGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColorInterpolated.withValues(alpha: 0.1),
        Colors.transparent,
        baseColorInterpolated.withValues(alpha: 0.15),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final overlayPaint = Paint()
      ..shader = overlayGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(FluidMeshPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.targetColor != targetColor ||
        oldDelegate.morphProgress != morphProgress ||
        oldDelegate.time != time;
  }
}

/// Widget wrapper for the animated background
class PortalBackground extends StatelessWidget {
  const PortalBackground({
    required this.baseColor,
    required this.targetColor,
    required this.morphProgress,
    required this.time,
    super.key,
  });

  final Color baseColor;
  final Color targetColor;
  final double morphProgress;
  final double time;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FluidMeshPainter(
        baseColor: baseColor,
        targetColor: targetColor,
        morphProgress: morphProgress,
        time: time,
      ),
      size: Size.infinite,
    );
  }
}
