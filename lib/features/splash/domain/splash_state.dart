import 'package:equatable/equatable.dart';

/// State for the splash screen animation and exit flow.
class SplashState extends Equatable {
  const SplashState({this.exitAnimationComplete = false});

  final bool exitAnimationComplete;

  SplashState copyWith({bool? exitAnimationComplete}) {
    return SplashState(
      exitAnimationComplete: exitAnimationComplete ?? this.exitAnimationComplete,
    );
  }

  @override
  List<Object?> get props => [exitAnimationComplete];
}
