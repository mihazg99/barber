import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/splash/domain/splash_state.dart';
import 'package:barber/features/splash/presentation/bloc/splash_notifier.dart';

final splashNotifierProvider =
    StateNotifierProvider.autoDispose<SplashNotifier, BaseState<SplashState>>(
  (ref) => SplashNotifier(),
);

/// True when the splash exit (Phase 4) animation has completed; router uses
/// this to allow redirect to Home/Auth.
final splashExitCompleteProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(splashNotifierProvider);
  if (state is BaseData<SplashState>) {
    return state.data.exitAnimationComplete;
  }
  return false;
});
