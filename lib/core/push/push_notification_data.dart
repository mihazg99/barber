import 'package:firebase_messaging/firebase_messaging.dart';

/// State for push notifications: token, permission, and optional messages
/// for foreground/initial handling.
class PushNotificationData {
  const PushNotificationData({
    this.fcmToken,
    this.authorizationStatus,
    this.lastForegroundMessage,
    this.initialMessage,
  });

  final String? fcmToken;
  final AuthorizationStatus? authorizationStatus;
  final RemoteMessage? lastForegroundMessage;
  final RemoteMessage? initialMessage;

  PushNotificationData copyWith({
    String? fcmToken,
    AuthorizationStatus? authorizationStatus,
    RemoteMessage? lastForegroundMessage,
    RemoteMessage? initialMessage,
    bool clearForegroundMessage = false,
    bool clearInitialMessage = false,
  }) {
    return PushNotificationData(
      fcmToken: fcmToken ?? this.fcmToken,
      authorizationStatus: authorizationStatus ?? this.authorizationStatus,
      lastForegroundMessage: clearForegroundMessage
          ? null
          : (lastForegroundMessage ?? this.lastForegroundMessage),
      initialMessage:
          clearInitialMessage ? null : (initialMessage ?? this.initialMessage),
    );
  }
}
