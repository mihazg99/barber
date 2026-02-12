import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/features/brand/domain/entities/brand_entity.dart';

/// Phases of the portal experience
enum PortalPhase {
  /// Initial neutral state with sapphire background
  neutral,

  /// Morphing animation in progress (color bleeding, card scaling)
  morphing,

  /// Morph complete, brand fully revealed
  revealed,

  /// Hero transition to next screen
  heroTransition,
}

/// State for the Portal page
@immutable
class PortalState extends Equatable {
  const PortalState({
    required this.phase,
    this.selectedBrand,
    this.morphProgress = 0.0,
  });

  final PortalPhase phase;
  final BrandEntity? selectedBrand;
  final double morphProgress; // 0.0 to 1.0

  const PortalState.initial()
      : phase = PortalPhase.neutral,
        selectedBrand = null,
        morphProgress = 0.0;

  PortalState copyWith({
    PortalPhase? phase,
    BrandEntity? selectedBrand,
    double? morphProgress,
  }) {
    return PortalState(
      phase: phase ?? this.phase,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      morphProgress: morphProgress ?? this.morphProgress,
    );
  }

  @override
  List<Object?> get props => [phase, selectedBrand, morphProgress];
}

/// Notifier for managing portal state transitions
class PortalNotifier extends StateNotifier<PortalState> {
  PortalNotifier() : super(const PortalState.initial());

  /// Called when a brand is selected (via QR or search)
  void onBrandSelected(BrandEntity brand) {
    if (state.phase != PortalPhase.neutral) {
      debugPrint('[PortalNotifier] Brand selection ignored - not in neutral phase');
      return;
    }

    debugPrint('[PortalNotifier] Brand selected: ${brand.name}');
    state = state.copyWith(
      phase: PortalPhase.morphing,
      selectedBrand: brand,
    );
  }

  /// Update morph progress during animation
  void updateMorphProgress(double progress) {
    if (state.phase == PortalPhase.morphing) {
      state = state.copyWith(morphProgress: progress);
    }
  }

  /// Called when morphing animation completes
  void onMorphComplete() {
    if (state.phase != PortalPhase.morphing) return;

    debugPrint('[PortalNotifier] Morph complete');
    state = state.copyWith(
      phase: PortalPhase.revealed,
      morphProgress: 1.0,
    );
  }

  /// Called when hero transition starts
  void onHeroTransitionStart() {
    if (state.phase != PortalPhase.revealed) return;

    debugPrint('[PortalNotifier] Hero transition starting');
    state = state.copyWith(phase: PortalPhase.heroTransition);
  }

  /// Reset to neutral state (for brand switching)
  void reset() {
    debugPrint('[PortalNotifier] Resetting to neutral state');
    state = const PortalState.initial();
  }

  /// Check if portal is ready for interaction
  bool get canInteract => state.phase == PortalPhase.neutral;

  /// Check if morphing is in progress
  bool get isMorphing => state.phase == PortalPhase.morphing;

  /// Check if brand is revealed
  bool get isRevealed => state.phase == PortalPhase.revealed;
}
