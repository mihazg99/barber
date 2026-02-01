sealed class BaseState<T> {
  const BaseState();
}

class BaseInitial<T> extends BaseState<T> {
  const BaseInitial();
}

class BaseLoading<T> extends BaseState<T> {
  const BaseLoading();
}

class BaseData<T> extends BaseState<T> {
  final T data;
  const BaseData(this.data);
}

class BaseError<T> extends BaseState<T> {
  final String message;
  final Object? error;
  
  const BaseError(this.message, [this.error]);
} 