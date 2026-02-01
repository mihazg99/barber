import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingCompleted = 'onboarding_completed';

/// Local persistence for onboarding completion (SharedPreferences).
class OnboardingLocalDataSource {
  OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> hasCompletedOnboarding() async {
    return hasCompletedOnboardingSync;
  }

  /// Synchronous read for router redirect.
  bool get hasCompletedOnboardingSync =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }
}
