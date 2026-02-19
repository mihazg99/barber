import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/di.dart';

/// Reusable cinematic video background widget with color grading
/// Can be used across onboarding, portal, or any other screen
class VideoBackground extends HookConsumerWidget {
  const VideoBackground({
    this.targetColor,
    this.morphProgress = 0.0,
    this.opacity = 0.65,
    this.baseColor = const Color(0xFF4338CA),
    super.key,
  });

  final Color? targetColor;
  final double morphProgress;
  final double opacity;
  final Color baseColor;

  /// Smart Color Normalization - Ensures deep, cinematic colors
  /// Rules:
  /// - If luminance > 0.6, darken to 0.5 (prevent blown-out brightness)
  /// - If saturation > 0.8, desaturate to 0.6 (prevent neon overload)
  Color _normalizeColor(Color color) {
    final hslColor = HSLColor.fromColor(color);

    // Normalize lightness: cap at 0.5 if too bright
    final normalizedLightness =
        hslColor.lightness > 0.6 ? 0.5 : hslColor.lightness;

    // Normalize saturation: cap at 0.6 if too intense
    final normalizedSaturation =
        hslColor.saturation > 0.8 ? 0.6 : hslColor.saturation;

    // Return normalized color
    return hslColor
        .withLightness(normalizedLightness)
        .withSaturation(normalizedSaturation)
        .toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get preloaded video controller from service
    final videoPreloader = ref.watch(videoPreloaderServiceProvider);
    final controller = videoPreloader.portalVideoController;

    final isInitialized = useState(false);
    final isMounted = useIsMounted();

    // Play preloaded video or fallback to loading new one
    useEffect(() {
      void init() async {
        try {
          if (controller != null && videoPreloader.isPortalVideoReady) {
            // Video already preloaded during splash - just play it
            debugPrint('[VideoBackground] Using preloaded video');
            if (!controller.value.isPlaying && isMounted()) {
              await controller.play();
            }
            if (isMounted()) {
              isInitialized.value = true;
            }
          } else {
            // Fallback: video wasn't preloaded or was disposed
            debugPrint('[VideoBackground] Video not ready, loading now...');
            await videoPreloader.preloadPortalVideo();
            if (videoPreloader.portalVideoController != null && isMounted()) {
              await videoPreloader.portalVideoController!.play();
              if (isMounted()) {
                isInitialized.value = true;
              }
            }
          }
        } catch (e) {
          debugPrint('[VideoBackground] Error playing video: $e');
        }
      }

      init();

      return () {
        // Don't dispose the controller here - it's managed by the service
        // Just log for debugging
        debugPrint('[VideoBackground] Widget disposed');
      };
    }, []);

    // Smart color normalization: ensure target color is deep and cinematic
    final normalizedTargetColor =
        targetColor != null ? _normalizeColor(targetColor!) : baseColor;

    // Color grading: lerp from base color to normalized target color
    final filterColor =
        Color.lerp(
          baseColor,
          normalizedTargetColor,
          morphProgress,
        )!;

    // Get absolute screen dimensions to prevent keyboard-induced resizing
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          // Base solid background layer
          Container(
            color: context.appColors.backgroundColor,
          ),

          // Video layer with color grading and luminance control
          if (isInitialized.value &&
              controller != null &&
              controller.value.isInitialized)
            Opacity(
              opacity: opacity,
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.1, // Scale to hide watermark
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      filterColor,
                      BlendMode.screen,
                    ),
                    child: SizedBox(
                      width: screenSize.width,
                      height: screenSize.height,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
