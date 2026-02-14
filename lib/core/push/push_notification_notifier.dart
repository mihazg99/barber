import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';

import 'push_notification_data.dart';

/// Callback to get the current signed-in user ID. Used to sync FCM token to
/// the user document when token is obtained or refreshed.
typedef GetCurrentUserId = String? Function();

/// Notifier for FCM: permission, token, and foreground/initial message handling.
/// Syncs token to the current user document when available.
class PushNotificationNotifier extends BaseNotifier<PushNotificationData, dynamic> {
  PushNotificationNotifier(
    this._messaging,
    this._userRepository,
    this._getCurrentUserId,
  ) {
    _init();
  }

  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;
  final GetCurrentUserId _getCurrentUserId;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<void> _init() async {
    setLoading();
    try {
      // iOS: show heads-up when app is in foreground
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging.getToken();
      // ignore: avoid_print
      print('FCM token: $token');
      final initialMessage = await _messaging.getInitialMessage();

      await _syncTokenToUser(token);

      if (mounted) {
        setData(PushNotificationData(
          fcmToken: token,
          authorizationStatus: settings.authorizationStatus,
          initialMessage: initialMessage,
        ));
      }

      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        // ignore: avoid_print
        print('FCM token refreshed: $newToken');
        _syncTokenToUser(newToken);
        if (mounted) {
          final current = data;
          if (current != null) {
            setData(current.copyWith(fcmToken: newToken));
          } else {
            setData(PushNotificationData(fcmToken: newToken));
          }
        }
      });

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (mounted) {
          final current = data;
          if (current != null) {
            setData(current.copyWith(lastForegroundMessage: message));
          } else {
            setData(PushNotificationData(lastForegroundMessage: message));
          }
        }
      });
    } catch (e) {
      if (mounted) setError('Push setup failed: $e', e);
    }
  }

  Future<void> _syncTokenToUser(String? token) async {
    if (token == null || token.isEmpty) return;
    final userId = _getCurrentUserId();
    if (userId == null || userId.isEmpty) return;
    await _userRepository.updateFcmToken(userId, token);
  }

  /// Clears the last foreground message (e.g. after showing in-app UI).
  void clearLastForegroundMessage() {
    final current = data;
    if (current != null) {
      setData(current.copyWith(clearForegroundMessage: true));
    }
  }

  /// Clears the initial message (e.g. after handling navigation from cold start).
  void clearInitialMessage() {
    final current = data;
    if (current != null) {
      setData(current.copyWith(clearInitialMessage: true));
    }
  }

  /// Re-request permission and refresh token. Call after user grants permission
  /// from settings.
  Future<void> refreshPermissionAndToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await _messaging.getToken();
    await _syncTokenToUser(token);
    if (mounted) {
      final current = data;
      setData((current ?? const PushNotificationData()).copyWith(
        fcmToken: token,
        authorizationStatus: settings.authorizationStatus,
      ));
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
