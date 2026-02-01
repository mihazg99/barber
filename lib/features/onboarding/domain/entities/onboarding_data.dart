import 'package:equatable/equatable.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_page_entity.dart';

/// Onboarding UI state: pages and current index.
class OnboardingData extends Equatable {
  const OnboardingData({
    required this.pages,
    this.currentPageIndex = 0,
  });

  final List<OnboardingPageEntity> pages;
  final int currentPageIndex;

  bool get isFirstPage => currentPageIndex == 0;
  bool get isLastPage => currentPageIndex >= pages.length - 1;

  OnboardingData copyWith({
    List<OnboardingPageEntity>? pages,
    int? currentPageIndex,
  }) {
    return OnboardingData(
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object?> get props => [pages, currentPageIndex];
}
