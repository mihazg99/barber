import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:inventory/core/errors/failure.dart';
import 'base_notifier.dart';
import 'base_state.dart';
import 'base_provider.dart';

// Example: User data model
class User {
  final String name;
  final String email;
  
  const User({required this.name, required this.email});
}



// Example: User notifier extending BaseNotifier
class UserNotifier extends BaseNotifier<User, Failure> {
  // Simulated API call returning Either
  Future<Either<Failure, User>> apiCallReturningEither() async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulate success
    return right(const User(name: 'John Doe', email: 'john@example.com'));
    // To simulate failure, uncomment:
    // return left(const Failure('Network error'));
  }

  Future<Either<Failure, User>> updateUserApiCall(String name, String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate success
    return right(User(name: name, email: email));
    // To simulate failure, uncomment:
    // return left(const Failure('Update failed'));
  }

  Future<void> fetchUser() async {
    await execute(
      () => apiCallReturningEither(),
      (failure) => failure.message,
    );
  }

  Future<void> updateUser(String name) async {
    if (data == null) {
      setError('No user data available');
      return;
    }
    await executeWithDefault(
      () => updateUserApiCall(name, data!.email),
    );
  }

  Future<void> resetUser() async {
    setInitial();
  }
}

// Example: Provider using BaseProvider factory
final userProvider = BaseProvider.create<UserNotifier, User>(
  () => UserNotifier(),
);

// Example: Selectors for specific states
final userDataProvider = Provider<User?>((ref) {
  final state = ref.watch(userProvider);
  return switch (state) {
    BaseData(:final data) => data,
    _ => null,
  };
});

final userLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(userProvider);
  return state is BaseLoading;
});

final userErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(userProvider);
  if (state is BaseError<User>) {
    return state.message;
  }
  return null;
}); 