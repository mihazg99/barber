/// A sealed class representing the high-level state of the application
/// for navigation purposes.
sealed class AppStage {
  const AppStage();
}

/// The application is initializing or loading critical data.
/// Replaces AsyncLoading for synchronous AppStageNotifier.
class LoadingStage extends AppStage {
  const LoadingStage();

  @override
  String toString() => 'LoadingStage';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingStage && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

/// The user is new and hasn't completed the onboarding flow.
class OnboardingStage extends AppStage {
  const OnboardingStage();

  @override
  String toString() => 'OnboardingStage';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStage && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

/// The user (Guest or Auth) has completed onboarding but has no brand selected.
/// They must go to the video portal/brand switcher.
class BrandSelectionStage extends AppStage {
  const BrandSelectionStage();

  @override
  String toString() => 'BrandSelectionStage';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandSelectionStage && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

/// The user is ready to use the main app (Home/Dashboard).
/// This applies to both authenticated users and guests with a locked brand.
class MainAppStage extends AppStage {
  final bool isStaff;
  const MainAppStage({this.isStaff = false});

  @override
  String toString() => 'MainAppStage(isStaff: $isStaff)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainAppStage &&
          runtimeType == other.runtimeType &&
          isStaff == other.isStaff;

  @override
  int get hashCode => 0 ^ isStaff.hashCode;
}

/// (Optional) Billing or Subscription lock.
class BillingLockedStage extends AppStage {
  const BillingLockedStage();

  @override
  String toString() => 'BillingLockedStage';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingLockedStage && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}
