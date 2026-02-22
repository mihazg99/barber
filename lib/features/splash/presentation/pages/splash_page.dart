import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/router/app_stage.dart';
import 'package:barber/core/router/app_stage_notifier.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/features/brand/di.dart' as brand_di;
import 'package:barber/features/splash/di.dart';
import 'package:barber/gen/assets.gen.dart';

/// High-end 4-phase splash: Architectural Snap (cage) → Organic Awakening (eye)
/// → Emerald Bloom (pulse) → Lens-flare exit on init complete.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _preloadVideo();
  }

  Future<void> _preloadVideo() async {
    final videoPreloader = ref.read(videoPreloaderServiceProvider);
    await videoPreloader.preloadPortalVideo();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(flavorConfigProvider);
    ref.watch(appColorsProvider);
    final lockedBrandId = ref.watch(brand_di.lockedBrandIdProvider);
    if (lockedBrandId != null && lockedBrandId.isNotEmpty) {
      ref.watch(brand_di.defaultBrandProvider);
    }

    return const Scaffold(
      body: _SplashBody(),
    );
  }
}

/// Zinc 950 background; centers the cage + eye symbol and runs the 4-phase sequence.
class _SplashBody extends ConsumerWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _SplashColors.background,
      child: SafeArea(
        child: _SplashSymbolStack(),
      ),
    );
  }
}

/// Phase 1: 0–800ms. Phase 2: 200ms delay then eye. Phase 3: 1200–2200ms pulse.
/// Phase 4: on init complete, scale to 15, then mark exit.
class _SplashSymbolStack extends HookConsumerWidget {
  const _SplashSymbolStack();

  static const Duration _phase3Start = Duration(milliseconds: 1200);
  static const Duration _phase3End = Duration(milliseconds: 2200);
  static const Duration _exitDuration = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStage = ref.watch(appStageProvider);
    final initComplete = appStage is! LoadingStage;

    // Main timeline: 0 → 2.2s (cage, then eye)
    final mainController = useAnimationController(
      duration: _phase3End,
    );

    // Phase 3: repeating pulse (bloom + eye ±2%)
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
      initialValue: 0,
    );

    // Phase 4: exit (scale 15)
    final exitController = useAnimationController(
      duration: _exitDuration,
      initialValue: 0,
    );

    // Start main animation immediately
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mainController.forward();
      });
      return null;
    }, [mainController]);

    // Start pulse when we reach Phase 3 (1.2s); stop when exit starts
    useEffect(() {
      void listener() {
        final phase3Start =
            _phase3Start.inMilliseconds / _phase3End.inMilliseconds;
        if (mainController.value >= phase3Start &&
            !initComplete &&
            pulseController.status != AnimationStatus.forward) {
          pulseController.repeat(reverse: true);
        }
      }

      mainController.addListener(listener);
      if (mainController.value >=
              _phase3Start.inMilliseconds / _phase3End.inMilliseconds &&
          !initComplete) {
        pulseController.repeat(reverse: true);
      }
      return () {
        mainController.removeListener(listener);
        pulseController.stop();
      };
    }, [mainController, pulseController, initComplete]);

    // Track if exit has been started to prevent double-triggering
    final exitStartedRef = useRef(false);

    // Exit logic: wait for main animation to complete, then exit if init is complete
    useEffect(() {
      void tryExit() {
        if (exitStartedRef.value ||
            exitController.status == AnimationStatus.forward ||
            exitController.status == AnimationStatus.completed) {
          return;
        }

        final mainDone = mainController.status == AnimationStatus.completed;

        if (mainDone && initComplete) {
          exitStartedRef.value = true;
          pulseController.stop();
          exitController.forward().then((_) {
            ref
                .read(splashNotifierProvider.notifier)
                .markExitAnimationComplete();
          });
        }
      }

      void onMainStatusChange(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          tryExit();
        }
      }

      mainController.addStatusListener(onMainStatusChange);
      tryExit();

      return () {
        mainController.removeStatusListener(onMainStatusChange);
      };
    }, [initComplete, exitController, pulseController, mainController, ref]);

    // Animations
    final cageOpacity = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: mainController,
          curve: const Interval(0.0, 800 / 2200, curve: Curves.easeOutExpo),
        ),
      ),
      [mainController],
    );

    final cageScale = useMemoized(
      () => Tween<double>(begin: 1.3, end: 1.0).animate(
        CurvedAnimation(
          parent: mainController,
          curve: const Interval(0, 800 / 2200, curve: Curves.easeOutExpo),
        ),
      ),
      [mainController],
    );

    const phase2Start = 200 / 2200;
    const phase2End = 1500 / 2200;
    final eyeOpacity = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: mainController,
          curve: Interval(phase2Start, phase2End, curve: Curves.easeInOutSine),
        ),
      ),
      [mainController],
    );

    final eyeScale = useMemoized(
      () => Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: mainController,
          curve: Interval(phase2Start, phase2End, curve: Curves.easeInOutSine),
        ),
      ),
      [mainController],
    );

    // Phase 3: eye pulse ±2% (0.98–1.02)
    final eyePulseScale = useMemoized(
      () => Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOutSine),
      ),
      [pulseController],
    );

    // Phase 4: exit scale 1 → 15
    final exitScale = useMemoized(
      () => Tween<double>(begin: 1.0, end: 15.0).animate(
        CurvedAnimation(parent: exitController, curve: Curves.easeIn),
      ),
      [exitController],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              mainController,
              pulseController,
              exitController,
            ]),
            builder: (context, child) {
              final exitScaleValue =
                  exitController.value > 0 ? exitScale.value : 1.0;
              final cageScaleValue = cageScale.value;
              final eyeScaleValue = pulseController.isAnimating
                  ? eyeScale.value * eyePulseScale.value
                  : eyeScale.value;

              return Transform.scale(
                scale: exitScaleValue,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _CageLayer(
                        opacity: cageOpacity.value,
                        scale: cageScaleValue,
                      ),
                      _EyeLayer(
                        opacity: eyeOpacity.value,
                        scale: eyeScaleValue,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (pulseController.isAnimating)
          _BloomOverlay(animation: pulseController),
      ],
    );
  }
}

class _CageLayer extends StatelessWidget {
  const _CageLayer({required this.opacity, required this.scale});

  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);

    if (clampedOpacity <= 0) {
      return const SizedBox.shrink();
    }

    // Cage PNG is 293x293 at 4x multiplier, so logical size is 73.25x73.25
    // Using 100px for better visibility and scaling
    const baseSize = 100.0;

    return Opacity(
      opacity: clampedOpacity,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: SizedBox(
          width: baseSize,
          height: baseSize,
          child: Assets.images.cage.image(
            key: const ValueKey('cage_image'),
            width: baseSize,
            height: baseSize,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticLabel: 'Cage',
          ),
        ),
      ),
    );
  }
}

class _EyeLayer extends StatelessWidget {
  const _EyeLayer({required this.opacity, required this.scale});

  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);

    if (clampedOpacity <= 0) {
      return const SizedBox.shrink();
    }

    // Eye PNG is 128x64 at 4x multiplier, so logical size is 32x16 (2:1 aspect ratio)
    // Cage logical: 73.25px, Eye logical: 32x16px
    // Ratio: eye width is ~43.7% of cage (32/73.25)
    // So at 100px cage, eye should be ~44x22px to maintain proportions
    const eyeWidth = 44.0;
    const eyeHeight = 22.0; // 2:1 aspect ratio, proportional to cage

    return Opacity(
      opacity: clampedOpacity,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: SizedBox(
          width: eyeWidth,
          height: eyeHeight,
          child: Assets.images.eye.image(
            key: const ValueKey('eye_image'),
            width: eyeWidth,
            height: eyeHeight,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticLabel: 'Eye',
          ),
        ),
      ),
    );
  }
}

/// Phase 3: subtle bloom glow around the symbol.
class _BloomOverlay extends HookWidget {
  const _BloomOverlay({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final intensity = 0.15 + 0.08 * (0.5 + 0.5 * animation.value);
            return Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _SplashColors.emerald.withValues(alpha: intensity),
                    blurRadius: 50,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: _SplashColors.emerald.withValues(
                      alpha: intensity * 0.5,
                    ),
                    blurRadius: 80,
                    spreadRadius: -10,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplashColors {
  _SplashColors._();

  static const Color background = Color(0xFF09090B); // Zinc 950
  static const Color emerald = Color(0xFF2DD4BF); // Emerald
}
