import 'package:equatable/equatable.dart';

import 'package:barber/features/auth/domain/entities/user_role.dart';

/// App user (client). doc_id: user_uid (Firebase Auth UID)
class UserEntity extends Equatable {
  const UserEntity({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.fcmToken,
    this.role = UserRole.user,
    this.lastBookingDate,
    this.nextVisitDue,
    this.averageVisitInterval = 30,
    this.lifetimeValue = 0.0,
    this.remindedThisCycle = false,
    this.preferredBarberId = '',
    this.barberId = '',
    this.brandId = '',
    this.dataVersions = const {},
  });

  final String userId;
  final String fullName;
  final String phone;
  final String fcmToken;

  /// User role. Only [UserRole.user] can be self-assigned. barber/superadmin via Admin SDK.
  final UserRole role;

  /// Last booking completion date (set by Cloud Function onBookingComplete).
  final DateTime? lastBookingDate;

  /// Next visit due date (lastBookingDate + averageVisitInterval days).
  final DateTime? nextVisitDue;

  /// Average days between visits. Default 30.
  final int averageVisitInterval;

  /// Lifetime spend (sum of completed appointment prices).
  final double lifetimeValue;

  /// Whether a reminder was sent this cycle (reset on new booking).
  final bool remindedThisCycle;

  /// Barber ID from most recent completed appointment.
  final String preferredBarberId;

  /// Barber ID if this user record is linked to a barber.
  final String barberId;

  /// Brand ID this user belongs to (required for superadmins).
  final String brandId;

  /// Version counters for user-specific data (e.g. reward_redemptions).
  final Map<String, int> dataVersions;

  UserEntity copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? fcmToken,
    UserRole? role,
    DateTime? lastBookingDate,
    DateTime? nextVisitDue,
    int? averageVisitInterval,
    double? lifetimeValue,
    bool? remindedThisCycle,
    String? preferredBarberId,
    String? barberId,
    String? brandId,
    Map<String, int>? dataVersions,
  }) => UserEntity(
    userId: userId ?? this.userId,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    fcmToken: fcmToken ?? this.fcmToken,
    role: role ?? this.role,
    lastBookingDate: lastBookingDate ?? this.lastBookingDate,
    nextVisitDue: nextVisitDue ?? this.nextVisitDue,
    averageVisitInterval: averageVisitInterval ?? this.averageVisitInterval,
    lifetimeValue: lifetimeValue ?? this.lifetimeValue,
    remindedThisCycle: remindedThisCycle ?? this.remindedThisCycle,
    preferredBarberId: preferredBarberId ?? this.preferredBarberId,
    barberId: barberId ?? this.barberId,
    brandId: brandId ?? this.brandId,
    dataVersions: dataVersions ?? this.dataVersions,
  );

  @override
  List<Object?> get props => [
    userId,
    fullName,
    phone,
    fcmToken,
    role,
    lastBookingDate,
    nextVisitDue,
    averageVisitInterval,
    lifetimeValue,
    remindedThisCycle,
    preferredBarberId,
    barberId,
    brandId,
    dataVersions,
  ];
}
