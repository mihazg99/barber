import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/deep_link/deep_link_notifier.dart';
import 'package:barber/core/state/base_state.dart';

/// Manual StateNotifierProvider for [DeepLinkNotifier]. autoDispose so the
/// notifier and its stream subscriptions are cleaned up when not watched.
final deepLinkNotifierProvider = StateNotifierProvider.autoDispose<
    DeepLinkNotifier,
    BaseState<DeepLinkState>>((ref) {
  return DeepLinkNotifier(appLinks: AppLinks());
});
