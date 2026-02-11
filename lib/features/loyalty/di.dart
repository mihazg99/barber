import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/loyalty/presentation/bloc/loyalty_notifier.dart';
import 'package:barber/features/rewards/di.dart';

/// Provider for current user's loyalty points for the selected brand.
/// Returns 0 if no brand is selected or user hasn't joined the brand.
final currentUserLoyaltyPointsProvider = StreamProvider.autoDispose<int>((ref) {
  final selectedBrandId = ref.watch(lockedBrandIdProvider);
  if (selectedBrandId == null) return Stream.value(0);

  final userIdAsync = ref.watch(currentUserIdProvider);
  final userId = userIdAsync.valueOrNull;
  if (userId == null) return Stream.value(0);

  final userBrandsAsync = ref.watch(userBrandsProvider);
  return userBrandsAsync.when(
    data: (userBrands) {
      final userBrand =
          userBrands.where((ub) => ub.brandId == selectedBrandId).firstOrNull;
      return Stream.value(userBrand?.loyaltyPoints ?? 0);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

final loyaltyNotifierProvider =
    StateNotifierProvider<LoyaltyNotifier, BaseState<String?>>((ref) {
      final transaction = ref.watch(spendPointsTransactionProvider);
      return LoyaltyNotifier(transaction);
    });
