import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_notifier.dart';
import 'base_state.dart';

class BaseProvider {
  static StateNotifierProvider<T, BaseState<R>> create<T extends BaseNotifier<R, dynamic>, R>(
    T Function() create,
  ) {
    return StateNotifierProvider<T, BaseState<R>>((ref) => create());
  }
} 