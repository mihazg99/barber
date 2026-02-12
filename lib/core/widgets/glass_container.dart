import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Reusable glass container widget with premium glassmorphism effect
/// matching the secondary button style from portal
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.borderRadius = 16.0,
    this.blurSigma = 25.0,
    this.backgroundColor,
    this.borderColor,
    this.border,
    this.padding,
    this.boxShadow,
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            // Default glass effect: subtle white opacity
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.05),
            // Gradient border matching portal secondary button
            border:
                border ??
                Border.all(
                  width: 1.0,
                  color: borderColor ?? Colors.white.withValues(alpha: 0.25),
                ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
