import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Premium glassmorphic button with brand accent colors
/// Exact match to portal page _GlassButton implementation
class GlassPrimaryButton extends HookWidget {
  const GlassPrimaryButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = true,
    required this.accentColor,
    this.loading = false,
    this.enabled = true,
  });

  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color accentColor;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Subtle hover/press animation
    final isPressed = useState(false);

    final canTap = enabled && !loading && onTap != null;

    return GestureDetector(
      onTapDown: canTap ? (_) => isPressed.value = true : null,
      onTapUp:
          canTap
              ? (_) {
                isPressed.value = false;
                onTap?.call();
              }
              : null,
      onTapCancel: canTap ? () => isPressed.value = false : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed.value ? 0.98 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
          child: Stack(
            children: [
              // Semi-transparent background layer for consistent backdrop filter rendering
              // This ensures the button looks the same regardless of parent background
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    context.appSizes.borderRadius,
                  ),
                  color: const Color(0xFF0F172A).withValues(
                    alpha: 0.3,
                  ), // Semi-transparent to maintain glass effect
                ),
              ),
              // Glassmorphic button with backdrop filter
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isPrimary ? 15.0 : 10.0,
                  sigmaY: isPrimary ? 15.0 : 10.0,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: context.appSizes.paddingMedium,
                    horizontal: context.appSizes.paddingLarge,
                  ),
                  decoration: BoxDecoration(
                    // Subtle glass tint
                    color:
                        isPrimary
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(
                      context.appSizes.borderRadius,
                    ),
                    border: Border.all(
                      width: 1.5,
                      color:
                          isPrimary
                              ? accentColor.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.25),
                    ),
                    // Glowing gradient border - EXACT COPY FROM PORTAL
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isPrimary
                              ? [
                                accentColor.withValues(alpha: 0.4),
                                accentColor.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.15),
                              ]
                              : [
                                Colors.white.withValues(alpha: 0.2),
                                accentColor.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      // Glow effect
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: isPrimary ? 0.25 : 0.15,
                        ),
                        blurRadius: isPrimary ? 16 : 12,
                        spreadRadius: isPrimary ? 2 : 1,
                      ),
                      // Subtle depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (loading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isPrimary ? accentColor : Colors.white,
                            ),
                          ),
                        )
                      else ...[
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: isPrimary ? accentColor : Colors.white,
                            size: 24,
                          ),
                          Gap(context.appSizes.paddingMedium),
                        ],
                        Text(
                          label,
                          style: context.appTextStyles.button.copyWith(
                            color: isPrimary ? accentColor : Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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
}
