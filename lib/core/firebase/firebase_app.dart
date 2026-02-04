import 'package:barber/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase. Call before runApp.
/// Requires [firebase_options.dart] from `flutterfire configure`.
///
/// Persistence is enabled for better UX (logos, names, etc. work offline).
/// Booking-related queries use GetOptions(source: Source.server) to ensure
/// appointments and availability are always fresh and prevent double-booking.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
