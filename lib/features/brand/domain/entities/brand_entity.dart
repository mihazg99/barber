import 'package:equatable/equatable.dart';

/// Root configuration for each client (brand).
/// doc_id: brand_id (e.g. old-school-barber)
class BrandEntity extends Equatable {
  const BrandEntity({
    required this.brandId,
    required this.name,
    this.tag,
    required this.isMultiLocation,
    required this.primaryColor,
    required this.logoUrl,
    required this.contactEmail,
    required this.slotInterval,
    required this.bufferTime,
    this.cancelHoursMinimum = 0,
    this.loyaltyPointsMultiplier = 10,
    this.requireSmsVerification = false,
    this.currency = 'EUR',
    this.fontFamily = 'Inter',
    this.locale = 'hr',
    this.themeColors = const {},
    this.subscriptionStatus = 'incomplete',
    this.subscriptionStart,
    this.subscriptionEnd,
    this.subscriptionTrialEnd,
    this.planId,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.freeTrialDays = 0,
    this.dataVersions = const {},
  });

  final String brandId;
  final String name;
  final String? tag;
  final bool isMultiLocation;
  final String primaryColor; // Hex, e.g. "#0A0A0A"
  final String logoUrl;
  final String contactEmail;
  final int slotInterval; // minutes, e.g. 15 or 30
  final int bufferTime; // minutes between appointments
  /// Minimum hours before appointment that cancellation is allowed. E.g. 48 = user
  /// must cancel at least 48h before. 0 = allow cancel anytime.
  final int cancelHoursMinimum;

  /// Points awarded per 1€ spent when barber scans loyalty QR (e.g. 10 = 30€ → 300 points).
  final int loyaltyPointsMultiplier;

  /// Whether SMS verification is required after social login. Defaults to false when not set.
  final bool requireSmsVerification;

  // Theme & Locale Configuration
  final String currency;
  final String fontFamily;
  final String locale;
  final Map<String, String> themeColors;

  // Subscription Configuration
  final String
  subscriptionStatus; // active, trialing, past_due, canceled, unpaid, incomplete
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final DateTime? subscriptionTrialEnd;
  final String? planId;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final int freeTrialDays;

  // Sentinel Versioning
  final Map<String, int> dataVersions;

  /// Returns true if the subscription is active, trialing, or within the 3-day grace period.
  bool get isSubscriptionActive {
    if (subscriptionStatus == 'active' || subscriptionStatus == 'trialing') {
      return true;
    }
    // Grace period for past_due
    if (subscriptionStatus == 'past_due' && subscriptionEnd != null) {
      final gracePeriodEnd = subscriptionEnd!.add(const Duration(days: 3));
      return DateTime.now().isBefore(gracePeriodEnd);
    }
    return false;
  }

  BrandEntity copyWith({
    String? brandId,
    String? name,
    String? tag,
    bool? isMultiLocation,
    String? primaryColor,
    String? logoUrl,
    String? contactEmail,
    int? slotInterval,
    int? bufferTime,
    int? cancelHoursMinimum,
    int? loyaltyPointsMultiplier,
    bool? requireSmsVerification,
    String? currency,
    String? fontFamily,
    String? locale,
    Map<String, String>? themeColors,
    String? subscriptionStatus,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    DateTime? subscriptionTrialEnd,
    String? planId,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    int? freeTrialDays,
    Map<String, int>? dataVersions,
  }) => BrandEntity(
    brandId: brandId ?? this.brandId,
    name: name ?? this.name,
    tag: tag ?? this.tag,
    isMultiLocation: isMultiLocation ?? this.isMultiLocation,
    primaryColor: primaryColor ?? this.primaryColor,
    logoUrl: logoUrl ?? this.logoUrl,
    contactEmail: contactEmail ?? this.contactEmail,
    slotInterval: slotInterval ?? this.slotInterval,
    bufferTime: bufferTime ?? this.bufferTime,
    cancelHoursMinimum: cancelHoursMinimum ?? this.cancelHoursMinimum,
    loyaltyPointsMultiplier:
        loyaltyPointsMultiplier ?? this.loyaltyPointsMultiplier,
    requireSmsVerification:
        requireSmsVerification ?? this.requireSmsVerification,
    currency: currency ?? this.currency,
    fontFamily: fontFamily ?? this.fontFamily,
    locale: locale ?? this.locale,
    themeColors: themeColors ?? this.themeColors,
    subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    subscriptionStart: subscriptionStart ?? this.subscriptionStart,
    subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
    subscriptionTrialEnd: subscriptionTrialEnd ?? this.subscriptionTrialEnd,
    planId: planId ?? this.planId,
    stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
    stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
    freeTrialDays: freeTrialDays ?? this.freeTrialDays,
    dataVersions: dataVersions ?? this.dataVersions,
  );

  @override
  List<Object?> get props => [
    brandId,
    name,
    tag,
    isMultiLocation,
    primaryColor,
    logoUrl,
    contactEmail,
    slotInterval,
    bufferTime,
    cancelHoursMinimum,
    loyaltyPointsMultiplier,
    requireSmsVerification,
    currency,
    fontFamily,
    locale,
    themeColors,
    subscriptionStatus,
    subscriptionStart,
    subscriptionEnd,
    subscriptionTrialEnd,
    planId,
    stripeCustomerId,
    stripeSubscriptionId,
    freeTrialDays,
    dataVersions,
  ];
}
