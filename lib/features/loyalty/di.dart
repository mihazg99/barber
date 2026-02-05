import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/loyalty/presentation/bloc/loyalty_notifier.dart';
import 'package:barber/features/rewards/di.dart';

final loyaltyNotifierProvider =
    StateNotifierProvider<LoyaltyNotifier, BaseState<String?>>((ref) {
      final transaction = ref.watch(spendPointsTransactionProvider);
      return LoyaltyNotifier(transaction);
    });
