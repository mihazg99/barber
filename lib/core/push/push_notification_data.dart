import 'package:firebase_messaging/firebase_messaging.dart';

/// State for push notifications: token, permission, and optional messages
/// for foreground / background-open / cold-start (initial) handling.
class PushNotificationData {
  const PushNotificationData({
    this.fcmToken,
    this.authorizationStatus,
    this.lastForegroundMessage,
    this.lastOpenedMessage,
    this.initialMessage,
  });

  final String? fcmToken;
  final AuthorizationStatus? authorizationStatus;

  /// Last message received while the app was in the foreground.
  final RemoteMessage? lastForegroundMessage;

  /// Last notification the user tapped when the app was backgrounded.
  final RemoteMessage? lastOpenedMessage;

  /// Notification that launched the app from terminated state (cold start).
  final RemoteMessage? initialMessage;

  PushNotificationData copyWith({
    String? fcmToken,
    AuthorizationStatus? authorizationStatus,
    RemoteMessage? lastForegroundMessage,
    RemoteMessage? lastOpenedMessage,
    RemoteMessage? initialMessage,
    bool clearForegroundMessage = false,
    bool clearOpenedMessage = false,
    bool clearInitialMessage = false,
  }) {
    return PushNotificationData(
      fcmToken: fcmToken ?? this.fcmToken,
      authorizationStatus: authorizationStatus ?? this.authorizationStatus,
      lastForegroundMessage:
          clearForegroundMessage
              ? null
              : (lastForegroundMessage ?? this.lastForegroundMessage),
      lastOpenedMessage:
          clearOpenedMessage
              ? null
              : (lastOpenedMessage ?? this.lastOpenedMessage),
      initialMessage:
          clearInitialMessage ? null : (initialMessage ?? this.initialMessage),
    );
  }
}
