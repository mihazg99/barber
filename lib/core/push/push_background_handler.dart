import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background handler for FCM. Must be registered before runApp
/// via [FirebaseMessaging.onBackgroundMessage].
///
/// Keep this function top-level and use [@pragma('vm:entry-point')] so it
/// is not tree-shaken when the app is in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Optional: handle data when app was in background/terminated.
  // Use message.data for routing (e.g. appointment_id, type).
}
