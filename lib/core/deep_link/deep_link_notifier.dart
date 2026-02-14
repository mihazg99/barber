import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:barber/core/deep_link/app_path.dart';
import 'package:barber/core/deep_link/deep_link_routes.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_notifier.dart';

/// State for [DeepLinkNotifier]: holds the current pending [AppPath] to navigate to.
/// When [pendingPath] is null, there is nothing to consume.
class DeepLinkState {
  const DeepLinkState({this.pendingPath});

  final AppPath? pendingPath;

  const DeepLinkState.initial() : pendingPath = null;
}

/// Notifier that normalizes Universal/App Links and FCM data into a single
/// [AppPath] stream. GoRouter (or a listener) reacts to [state] and navigates,
/// then calls [consumePending] so the same link is not applied twice.
///
/// Listens to:
/// - [AppLinks.uriLinkStream] for links while app is running
/// - [FirebaseMessaging.onMessageOpenedApp] for notification tap (background)
/// Cold start: [setPendingFromInitialLink] and [setPendingFromInitialMessage]
/// must be called from a widget (e.g. [_DeepLinkHandler]) after app is ready.
class DeepLinkNotifier extends BaseNotifier<DeepLinkState, dynamic> {
  DeepLinkNotifier({required AppLinks appLinks}) : _appLinks = appLinks {
    _appLinksSubscription =
        _appLinks.uriLinkStream.listen(_onUriLink, onError: _onStreamError);
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    setData(const DeepLinkState.initial());
  }

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _appLinksSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  void _onUriLink(Uri uri) {
    final path = _normalizeUri(uri);
    if (path != null && mounted) {
      debugPrint('[DeepLink] App link received: ${path.location}');
      setData(DeepLinkState(pendingPath: path));
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final path = _normalizeFcmData(message.data);
    if (path != null && mounted) {
      debugPrint('[DeepLink] FCM opened: ${path.location}');
      setData(DeepLinkState(pendingPath: path));
    }
  }

  void _onStreamError(Object error, StackTrace st) {
    debugPrint('[DeepLink] Stream error: $error');
  }

  /// Call from cold start after app is ready (e.g. from [_DeepLinkHandler]).
  /// Pass the result of [AppLinks.getInitialLink].
  void setPendingFromInitialLink(Uri? uri) {
    if (uri == null) return;
    final path = _normalizeUri(uri);
    if (path != null && mounted) {
      debugPrint('[DeepLink] Initial link: ${path.location}');
      setData(DeepLinkState(pendingPath: path));
    }
  }

  /// Call from cold start after app is ready. Pass [RemoteMessage] from
  /// [FirebaseMessaging.instance.getInitialMessage].
  void setPendingFromInitialMessage(RemoteMessage? message) {
    if (message == null) return;
    final path = _normalizeFcmData(message.data);
    if (path != null && mounted) {
      debugPrint('[DeepLink] Initial FCM: ${path.location}');
      setData(DeepLinkState(pendingPath: path));
    }
  }

  /// Normalize an incoming URL (Universal/App Link) into [AppPath].
  AppPath? normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return _normalizeUri(uri);
    } catch (_) {
      return null;
    }
  }

  /// Normalize FCM [RemoteMessage.data] map into [AppPath].
  AppPath? normalizeFcmPayload(Map<String, dynamic> data) {
    return _normalizeFcmData(data);
  }

  AppPath? _normalizeUri(Uri uri) {
    final path = uri.path;
    if (path.isEmpty) return null;
    final queryParams = Map<String, String>.from(uri.queryParameters);
    final brandId = queryParams.remove('brandId');
    return (
      path: path,
      queryParams: queryParams,
      brandId: brandId,
    );
  }

  AppPath? _normalizeFcmData(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    final stringData = data.map((k, v) => MapEntry(k, v?.toString() ?? ''));

    String path;
    final queryParams = <String, String>{};
    String? brandId = stringData[DeepLinkRoutes.paramBrandId];

    if (stringData['path'] != null && stringData['path']!.isNotEmpty) {
      final uri = Uri.tryParse(stringData['path']!);
      if (uri != null) {
        path = uri.path;
        queryParams.addAll(uri.queryParameters);
        brandId ??= uri.queryParameters[DeepLinkRoutes.paramBrandId];
      } else {
        path = stringData['path']!;
      }
    } else {
      final type = stringData['type'] ?? stringData['route'];
      final appointmentId = stringData[DeepLinkRoutes.paramAppointmentId];
      if ((type == DeepLinkRoutes.fcmTypeManageBooking || type == 'edit_booking') &&
          appointmentId != null &&
          appointmentId.isNotEmpty) {
        final isEdit = type == 'edit_booking';
        path = (isEdit ? AppRoute.editBooking : AppRoute.manageBooking)
            .path
            .replaceFirst(':appointmentId', appointmentId);
      } else if (type == DeepLinkRoutes.fcmTypeBooking || type == 'book') {
        final created = DeepLinkRoutes.createBooking(
          brandId: brandId,
          barberId: stringData[DeepLinkRoutes.paramBarberId],
          serviceId: stringData[DeepLinkRoutes.paramServiceId],
          locationId: stringData[DeepLinkRoutes.paramLocationId],
        );
        path = created.path;
        queryParams.addAll(created.queryParams);
        brandId = created.brandId;
      } else if (type == DeepLinkRoutes.fcmTypeRewards ||
          type == DeepLinkRoutes.fcmTypeLoyalty) {
        final rewardsPath = DeepLinkRoutes.rewards(brandId: brandId);
        path = rewardsPath.path;
        brandId = rewardsPath.brandId;
      } else if (type == 'home') {
        path = AppRoute.home.path;
      } else {
        path = AppRoute.home.path;
      }
    }

    return (path: path, queryParams: queryParams, brandId: brandId);
  }

  /// After router has applied the pending path, call this to clear it.
  void consumePending() {
    if (data?.pendingPath != null && mounted) {
      setData(const DeepLinkState.initial());
    }
  }

  /// Current pending path, if any.
  AppPath? get pendingPath => data?.pendingPath;

  @override
  void dispose() {
    _appLinksSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    super.dispose();
  }
}
