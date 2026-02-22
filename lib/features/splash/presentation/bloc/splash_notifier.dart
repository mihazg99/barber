import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/splash/domain/splash_state.dart';

/// Tracks splash animation phase and signals when exit (Phase 4) is complete
/// so the router can redirect to Home/Auth.
class SplashNotifier extends BaseNotifier<SplashState, void> {
  SplashNotifier() : super() {
    state = BaseData(const SplashState());
  }

  /// Call when the lens-flare / white-out exit animation has finished.
  /// Router waits for this before redirecting off splash.
  void markExitAnimationComplete() {
    setData(const SplashState(exitAnimationComplete: true));
  }
}
