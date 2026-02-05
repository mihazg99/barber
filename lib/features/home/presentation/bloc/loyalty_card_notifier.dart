import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the loyalty card flip (front vs back).
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

  void flipToFront() => state = state.copyWith(isFlipped: false);
}
