import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_page_entity.dart'
    show OnboardingIcon, OnboardingPageEntity;
import 'package:barber/features/onboarding/domain/failures/onboarding_failures.dart';
import 'package:barber/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:barber/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:barber/gen/l10n/app_localizations.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    try {
      final completed = await _localDataSource.hasCompletedOnboarding();
      return Right(completed);
    } catch (e) {
      return Left(
        OnboardingStorageFailure('Failed to read onboarding state: $e'),
      );
    }
  }

  @override
  Future<Either<OnboardingStorageFailure, void>> completeOnboarding() async {
    try {
      await _localDataSource.setOnboardingCompleted(true);
      return const Right(null);
    } catch (e) {
      return Left(
        OnboardingStorageFailure('Failed to save onboarding state: $e'),
      );
    }
  }

  @override
  List<OnboardingPageEntity> getPages(String languageCode) {
    final l10n = lookupAppLocalizations(Locale(languageCode));
    return [
      OnboardingPageEntity(
        title: l10n.onboardingBookAppointmentsTitle,
        description: l10n.onboardingBookAppointmentsDescription,
        icon: OnboardingIcon.eventAvailable,
      ),
      OnboardingPageEntity(
        title: l10n.onboardingScanQrTitle,
        description: l10n.onboardingScanQrDescription,
        icon: OnboardingIcon.qrCodeScanner,
      ),
      OnboardingPageEntity(
        title: l10n.onboardingLoyaltyTitle,
        description: l10n.onboardingLoyaltyDescription,
        icon: OnboardingIcon.loyalty,
      ),
    ];
  }
}
