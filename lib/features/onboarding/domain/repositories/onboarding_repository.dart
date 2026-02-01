import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_page_entity.dart';
import 'package:barber/features/onboarding/domain/failures/onboarding_failures.dart';

abstract class OnboardingRepository {
  /// Returns whether the user has completed onboarding.
  Future<Either<Failure, bool>> hasCompletedOnboarding();

  /// Persists that the user has completed onboarding.
  Future<Either<OnboardingStorageFailure, void>> completeOnboarding();

  /// Returns the list of onboarding slides (static or from config).
  List<OnboardingPageEntity> getPages();
}
