/// Firestore collection names for the barbershop whitelabel database.
abstract final class FirestoreCollections {
  FirestoreCollections._();

  /// Root configuration for each client (brand).
  static const String brands = 'brands';

  /// Specific shops belonging to a brand.
  static const String locations = 'locations';

  /// Services offered by the brand.
  static const String services = 'services';

  /// Employees assigned to specific locations.
  static const String barbers = 'barbers';

  /// App users (clients).
  static const String users = 'users';

  /// Pre-calculated slots for fast booking.
  static const String availability = 'availability';

  /// Detailed records of all bookings.
  static const String appointments = 'appointments';

  /// One doc per user: { user_id, active_appointment_id }. Used for atomic
  /// "one active appointment per user" check in booking transactions.
  static const String userBookingLocks = 'user_booking_locks';

  /// Loyalty rewards catalog (per brand): redeemable items with points cost.
  static const String rewards = 'rewards';

  /// User reward redemptions: user spent points to "buy" a reward; doc id used in QR for barber to scan and mark redeemed.
  static const String rewardRedemptions = 'reward_redemptions';
}
