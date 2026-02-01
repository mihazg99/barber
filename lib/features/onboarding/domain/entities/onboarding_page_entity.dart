import 'package:equatable/equatable.dart';

/// Single onboarding slide (title, description, icon).
class OnboardingPageEntity extends Equatable {
  const OnboardingPageEntity({
    required this.title,
    required this.description,
    required this.iconCodePoint,
  });

  final String title;
  final String description;
  final int iconCodePoint;

  @override
  List<Object?> get props => [title, description, iconCodePoint];
}
