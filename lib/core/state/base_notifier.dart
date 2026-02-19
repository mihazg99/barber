import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'base_state.dart';

abstract class BaseNotifier<T, F> extends StateNotifier<BaseState<T>> {
  BaseNotifier() : super(const BaseInitial());

  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Explicit state transitions
  void setInitial() {
    if (!_mounted) return;
    state = const BaseInitial();
  }

  void setLoading() {
    if (!_mounted) return;
    state = const BaseLoading();
  }

  void setData(T data) {
    if (!_mounted) return;
    state = BaseData(data);
  }

  void setError(String message, [Object? error]) {
    if (!_mounted) return;
    state = BaseError(message, error);
  }

  // Main helper for Either - no need to specify failure type
  Future<void> execute(
    Future<Either<F, T>> Function() operation,
    String Function(F failure) errorMessageBuilder,
  ) async {
    setLoading();
    final result = await operation();
    result.fold(
      (failure) => setError(errorMessageBuilder(failure), failure),
      (data) => setData(data),
    );
  }

  // Helper with default error message
  Future<void> executeWithDefault(
    Future<Either<F, T>> Function() operation,
  ) async {
    setLoading();
    final result = await operation();
    result.fold(
      (failure) => setError('Operation failed', failure),
      (data) => setData(data),
    );
  }

  // State getters
  bool get isLoading => state is BaseLoading;
  bool get hasData => state is BaseData;
  bool get hasError => state is BaseError;
  bool get isInitial => state is BaseInitial;

  T? get data {
    if (state is BaseData) {
      return (state as BaseData<T>).data;
    }
    return null;
  }

  String? get errorMessage {
    if (state is BaseError) {
      return (state as BaseError<T>).message;
    }
    return null;
  }

  Object? get error {
    if (state is BaseError) {
      return (state as BaseError<T>).error;
    }
    return null;
  }
}
