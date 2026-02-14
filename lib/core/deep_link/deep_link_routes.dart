import 'package:barber/core/deep_link/app_path.dart';
import 'package:barber/core/router/app_routes.dart';

/// Core user-facing deep link routes: manage booking, create booking, rewards.
///
/// Full documentation: see README.md in this directory (flow, FCM payloads,
/// where the cold-start handler is mounted, and auth/brand behaviour).
///
/// ## Universal/App Link URL forms
///
/// - **Manage booking:** `https://<host>/manage_booking/<appointmentId>?brandId=<id>`
/// - **Create booking:** `https://<host>/booking?brandId=&barberId=&serviceId=&locationId=`
/// - **Rewards:** `https://<host>/loyalty?brandId=<id>`
///
/// ## FCM data payloads
///
/// Use `type` (or `route`) plus the keys below. [brandId] is applied before navigation.
///
/// | Route            | type              | Keys (all optional except where noted)     |
/// |------------------|-------------------|--------------------------------------------|
/// | Manage booking   | `manage_booking`  | `appointmentId` (required), `brandId`      |
/// | Create booking  | `booking` / `book`| `brandId`, `barberId`, `serviceId`, `locationId` |
/// | Rewards          | `rewards` / `loyalty` | `brandId`                              |
///
/// Alternative: send a full path in `data.path`, e.g. `"/manage_booking/abc123?brandId=xyz"`.
abstract final class DeepLinkRoutes {
  DeepLinkRoutes._();

  // ---------------------------------------------------------------------------
  // Path segments (match GoRouter paths)
  // ---------------------------------------------------------------------------

  static const String manageBookingPath = '/manage_booking';
  static const String bookingPath = '/booking';
  static const String rewardsPath = '/loyalty';

  /// FCM data [type] / [route] values for normalization.
  static const String fcmTypeManageBooking = 'manage_booking';
  static const String fcmTypeBooking = 'booking';
  static const String fcmTypeRewards = 'rewards';
  static const String fcmTypeLoyalty = 'loyalty';

  /// Query param keys used in URLs and FCM data.
  static const String paramBrandId = 'brandId';
  static const String paramAppointmentId = 'appointmentId';
  static const String paramBarberId = 'barberId';
  static const String paramServiceId = 'serviceId';
  static const String paramLocationId = 'locationId';

  // ---------------------------------------------------------------------------
  // Build AppPath for each core route (for links / FCM payload generation)
  // ---------------------------------------------------------------------------

  /// Manage booking: view or manage an existing appointment.
  ///
  /// [appointmentId] is required. [brandId] is applied before navigation when set.
  static AppPath manageBooking(
    String appointmentId, {
    String? brandId,
  }) {
    final path =
        '${AppRoute.manageBooking.path.replaceFirst(':appointmentId', appointmentId)}';
    return (
      path: path,
      queryParams: const {},
      brandId: brandId,
    );
  }

  /// Create booking: open the booking flow, optionally with pre-selected barber/service/location.
  ///
  /// [brandId] is applied before navigation when set.
  static AppPath createBooking({
    String? brandId,
    String? barberId,
    String? serviceId,
    String? locationId,
  }) {
    final queryParams = <String, String>{};
    if (barberId != null && barberId.isNotEmpty) queryParams[paramBarberId] = barberId;
    if (serviceId != null && serviceId.isNotEmpty) queryParams[paramServiceId] = serviceId;
    if (locationId != null && locationId.isNotEmpty) queryParams[paramLocationId] = locationId;
    return (
      path: AppRoute.booking.path,
      queryParams: queryParams,
      brandId: brandId,
    );
  }

  /// Rewards (loyalty) route: points and rewards for the user.
  ///
  /// [brandId] is applied before navigation when set.
  static AppPath rewards({String? brandId}) {
    return (
      path: AppRoute.loyalty.path,
      queryParams: const {},
      brandId: brandId,
    );
  }
}
