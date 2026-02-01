import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:barber/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_data.dart';
import 'package:barber/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:barber/features/onboarding/presentation/bloc/onboarding_notifier.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((ref) {
  return OnboardingLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, BaseState<OnboardingData>>((ref) {
  return OnboardingNotifier(ref.watch(onboardingRepositoryProvider));
});

/// Sync read for router redirect. Invalidate after [OnboardingNotifier.complete].
final onboardingHasCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingLocalDataSourceProvider).hasCompletedOnboardingSync;
});
