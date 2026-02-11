import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the loyalty card flip (front vs back).
/// isFlipped=false shows FRONT (not flipped), isFlipped=true shows BACK (flipped over)
class LoyaltyCardState {
  const LoyaltyCardState({this.isFlipped = false});

  final bool isFlipped;

  LoyaltyCardState copyWith({bool? isFlipped}) =>
      LoyaltyCardState(isFlipped: isFlipped ?? this.isFlipped);
}

/// Notifier for loyalty card flip. AutoDispose so state resets when leaving.
class LoyaltyCardNotifier extends StateNotifier<LoyaltyCardState> {
  LoyaltyCardNotifier() : super(const LoyaltyCardState());

  void flip() => state = state.copyWith(isFlipped: !state.isFlipped);

  /// Show the front face (not flipped)
  void flipToFront() => state = state.copyWith(isFlipped: false);

  /// Show the back face (flipped)
  void flipToBack() => state = state.copyWith(isFlipped: true);
}
