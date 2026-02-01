import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_data.dart';
import 'package:barber/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingNotifier extends BaseNotifier<OnboardingData, dynamic> {
  OnboardingNotifier(this._repository);

  final OnboardingRepository _repository;

  /// Loads onboarding pages and sets initial state.
  void load() {
    final pages = _repository.getPages();
    setData(OnboardingData(pages: pages, currentPageIndex: 0));
  }

  void goToPage(int index) {
    final currentData = data;
    if (currentData == null || index < 0 || index >= currentData.pages.length) return;
    setData(currentData.copyWith(currentPageIndex: index));
  }

  void nextPage() {
    final currentData = data;
    if (currentData == null) return;
    if (currentData.isLastPage) return;
    setData(currentData.copyWith(currentPageIndex: currentData.currentPageIndex + 1));
  }

  void previousPage() {
    final currentData = data;
    if (currentData == null) return;
    if (currentData.isFirstPage) return;
    setData(currentData.copyWith(currentPageIndex: currentData.currentPageIndex - 1));
  }

  /// Marks onboarding as completed (persists and keeps current state).
  Future<void> complete() async {
    final result = await _repository.completeOnboarding();
    result.fold(
      (failure) => setError(failure.message, failure),
      (_) => setData(data!),
    );
  }
}
