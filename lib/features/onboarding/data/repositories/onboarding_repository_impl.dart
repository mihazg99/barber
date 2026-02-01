import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_page_entity.dart';
import 'package:barber/features/onboarding/domain/failures/onboarding_failures.dart';
import 'package:barber/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:barber/features/onboarding/data/datasources/onboarding_local_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    try {
      final completed = await _localDataSource.hasCompletedOnboarding();
      return Right(completed);
    } catch (e) {
      return Left(OnboardingStorageFailure('Failed to read onboarding state: $e'));
    }
  }

  @override
  Future<Either<OnboardingStorageFailure, void>> completeOnboarding() async {
    try {
      await _localDataSource.setOnboardingCompleted(true);
      return const Right(null);
    } catch (e) {
      return Left(OnboardingStorageFailure('Failed to save onboarding state: $e'));
    }
  }

  @override
  List<OnboardingPageEntity> getPages() {
    return [
      OnboardingPageEntity(
        title: 'Book appointments',
        description: 'Schedule your visit in a few taps and manage your bookings easily.',
        iconCodePoint: Icons.calendar_today.codePoint,
      ),
      OnboardingPageEntity(
        title: 'Scan QR codes',
        description: 'Quick check-in and access to services by scanning QR codes at the location.',
        iconCodePoint: Icons.qr_code_scanner.codePoint,
      ),
      OnboardingPageEntity(
        title: 'Manage inventory',
        description: 'Keep track of items and boxes across your locations.',
        iconCodePoint: Icons.inventory_2.codePoint,
      ),
    ];
  }
}
