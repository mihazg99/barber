import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background handler for FCM. Must be registered before runApp
/// via [FirebaseMessaging.onBackgroundMessage].
///
/// Keep this function top-level and annotated with [@pragma('vm:entry-point')]
/// so it is not tree-shaken when the app is in background/terminated.
///
/// Firebase MUST be initialized here before using any Firebase plugin.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Always initialize Firebase in the background isolate.
  await Firebase.initializeApp();

  // Handle background/terminated data messages here.
  // Use message.data for routing (e.g. appointment_id, type).
  // Do NOT update any UI — the app may not be running.
}
