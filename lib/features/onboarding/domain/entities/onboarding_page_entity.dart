import 'package:equatable/equatable.dart';

/// Icon identifier for onboarding slides. Used so the UI can map to const IconData for tree-shaking.
enum OnboardingIcon {
  eventAvailable,
  qrCodeScanner,
  loyalty,
}

/// Single onboarding slide (title, description, icon).
class OnboardingPageEntity extends Equatable {
  const OnboardingPageEntity({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final OnboardingIcon icon;

  @override
  List<Object?> get props => [title, description, icon];
}
