import 'package:barber/core/state/base_notifier.dart';

/// State for login overlay visibility and loading.
class LoginOverlayState {
  const LoginOverlayState({
    this.isVisible = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isVisible;
  final bool isLoading;
  final String? errorMessage;

  LoginOverlayState copyWith({
    bool? isVisible,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginOverlayState(
      isVisible: isVisible ?? this.isVisible,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier for managing login overlay state.
class LoginOverlayNotifier extends BaseNotifier<LoginOverlayState, void> {
  LoginOverlayNotifier() : super() {
    setData(const LoginOverlayState());
  }

  void show() {
    final current = data ?? const LoginOverlayState();
    setData(current.copyWith(isVisible: true, clearError: true));
  }

  void hide() {
    final current = data ?? const LoginOverlayState();
    setData(
      current.copyWith(isVisible: false, isLoading: false, clearError: true),
    );
  }

  void setLoadingState(bool loading) {
    final current = data ?? const LoginOverlayState();
    setData(current.copyWith(isLoading: loading, clearError: true));
  }

  void setErrorMessage(String message) {
    final current = data ?? const LoginOverlayState();
    setData(current.copyWith(isLoading: false, errorMessage: message));
  }
}
