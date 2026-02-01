import 'package:barber/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase. Call before runApp.
/// Requires [firebase_options.dart] from `flutterfire configure`.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
