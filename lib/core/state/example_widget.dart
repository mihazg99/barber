import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'base_state.dart';
import 'example_usage.dart';

class UserProfileWidget extends HookConsumerWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            onPressed: () => ref.read(userProvider.notifier).fetchUser(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (userState) {
        BaseInitial() => const Center(
            child: Text('No user data. Tap refresh to load.'),
          ),
        BaseLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        BaseData(:final data) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Name: ${data.name}'),
            
                const SizedBox(height: 8),
                Text('Email: ${data.email}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(userProvider.notifier)
                      .updateUser('Jane Doe'),
                  child: const Text('Update Name'),
                ),
              ],
            ),
          ),
        BaseError(:final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.appColors.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $message',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(userProvider.notifier).fetchUser(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      },
    );
  }
} 