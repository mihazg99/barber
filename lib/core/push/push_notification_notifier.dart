import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:barber/core/state/base_notifier.dart';

import 'push_notification_data.dart';

/// Notifier for FCM: permission, token, and foreground/initial message handling.
/// Syncs token to the current user document when available.
///
/// Not autoDispose — must outlive individual widgets so FCM subscriptions
/// (onTokenRefresh, onMessage) are never silently cancelled during the session.
class PushNotificationNotifier
    extends BaseNotifier<PushNotificationData, dynamic> {
  PushNotificationNotifier(this._messaging) {
    _init();
  }

  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundOpenSubscription;

  Future<void> _init() async {
    setLoading();
    try {
      // iOS: show heads-up notification banner when app is in foreground.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Do not request permission on startup; user is prompted in onboarding.
      final settings = await _messaging.getNotificationSettings();

      final token = await _getTokenSafely();
      debugPrint(
        '[FCM] Token: ${token != null ? '${token.substring(0, 20)}…' : 'null'}',
      );
      final initialMessage = await _messaging.getInitialMessage();

      if (mounted) {
        setData(
          PushNotificationData(
            fcmToken: token,
            authorizationStatus: settings.authorizationStatus,
            initialMessage: initialMessage,
          ),
        );
      }

      // Token rotations from Firebase — update Firestore via bootstrap provider.
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed');
        if (mounted) {
          final current = data;
          if (current != null) {
            setData(current.copyWith(fcmToken: newToken));
          } else {
            setData(PushNotificationData(fcmToken: newToken));
          }
        }
      });

      // Foreground messages — surface in-app UI.
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (mounted) {
          final current = data;
          if (current != null) {
            setData(current.copyWith(lastForegroundMessage: message));
          } else {
            setData(PushNotificationData(lastForegroundMessage: message));
          }
        }
      });

      // Background-open: user tapped a notification while app was backgrounded.
      _backgroundOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          if (mounted) {
            final current = data;
            if (current != null) {
              setData(current.copyWith(lastOpenedMessage: message));
            } else {
              setData(PushNotificationData(lastOpenedMessage: message));
            }
          }
        },
      );
    } catch (e) {
      if (mounted) setError('Push setup failed: $e', e);
    }
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

  /// Clears the background-opened message after navigation is handled.
  void clearLastOpenedMessage() {
    final current = data;
    if (current != null) {
      setData(current.copyWith(clearOpenedMessage: true));
    }
  }

  /// Fast permission request — resolves as soon as the iOS native dialog is
  /// dismissed (accept OR deny). Does NOT wait for the APNS/FCM token.
  ///
  /// Use this from onboarding so navigation continues immediately.
  /// The FCM token will arrive via [onTokenRefresh] or the background kick below.
  Future<void> requestPermissionOnly() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (mounted) {
      final current = data;
      setData(
        (current ?? const PushNotificationData()).copyWith(
          authorizationStatus: settings.authorizationStatus,
        ),
      );
    }
    // Kick off token fetch in the background — no await so caller can navigate
    // immediately. Token will arrive via onTokenRefresh or the fetch below.
    unawaited(_fetchAndStoreToken());
  }

  /// Re-request permission AND wait for the token. Use this from settings
  /// (the drawer toggle) where the user stays on the same screen.
  Future<void> refreshPermissionAndToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await _getTokenSafely();
    if (mounted) {
      final current = data;
      setData(
        (current ?? const PushNotificationData()).copyWith(
          fcmToken: token,
          authorizationStatus: settings.authorizationStatus,
        ),
      );
    }
  }

  /// Fetches the FCM token and stores it in state. Safe to call unawaited.
  Future<void> _fetchAndStoreToken() async {
    final token = await _getTokenSafely();
    if (mounted && token != null && token.isNotEmpty) {
      final current = data;
      setData(
        (current ?? const PushNotificationData()).copyWith(fcmToken: token),
      );
    }
  }

  /// Revokes the FCM token on sign-out so this device no longer receives
  /// push notifications for the signed-out user. A new token is minted on
  /// next [_getTokenSafely] call after re-login.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] deleteToken failed: $e');
    }
    if (mounted) {
      final current = data;
      setData(
        (current ?? const PushNotificationData()).copyWith(fcmToken: ''),
      );
    }
  }

  /// On iOS, FCM requires the APNS token to be present before it can mint an
  /// FCM token. This helper retries up to ~5 s to wait for it.
  Future<String?> _getTokenSafely() async {
    if (Platform.isIOS) {
      for (var i = 0; i < 10; i++) {
        try {
          final apns = await _messaging.getAPNSToken();
          if (apns != null) break;
        } catch (_) {
          // APNS token not yet available — wait and retry.
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed (APNS not ready?): $e');
      return null;
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _backgroundOpenSubscription?.cancel();
    super.dispose();
  }
}
