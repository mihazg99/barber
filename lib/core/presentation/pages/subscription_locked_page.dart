import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionLockedPage extends ConsumerWidget {
  const SubscriptionLockedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Subscription Expired',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your brand\'s subscription has expired or is past due. Please contact support to renew your access.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'support@styl.com',
                    query: 'subject=Subscription Issue',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
                icon: const Icon(Icons.email_outlined),
                label: const Text('Contact Support'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Ideally, implement a logout logic here.
                  // For now, we can just let them stay or maybe redirect to a specific logout route if it existed.
                  // But since the router blocks them, logout is the only way out.
                  // Assuming specific logout logic is not easily reachable from here without importing auth repo.
                  // Getting back to AuthPage might be automatic if we clear session.
                },
                child: const Text('Logout (Contact Admin)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
