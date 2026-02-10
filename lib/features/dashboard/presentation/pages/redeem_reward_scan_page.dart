import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/booking/di.dart' as booking_di;
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/rewards/di.dart';
import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/rewards/domain/repositories/redemption_repository.dart';
import 'package:barber/features/dashboard/di.dart' as dashboard_di;

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

Future<void> _handleRewardRedemption(
  BuildContext context,
  WidgetRef ref,
  String id,
  RedemptionEntity redemption,
  RedemptionRepository redemptionRepo,
  ValueNotifier<String?> lastScannedId,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => _RedeemConfirmDialog(
          rewardName: redemption.rewardName,
          pointsSpent: redemption.pointsSpent,
        ),
  );
  if (confirm != true || !context.mounted) return;
  final userId = ref.read(currentUserProvider).valueOrNull?.userId ?? '';
  final configBrandId =
      ref.read(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId = configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
  final redeemResult = await redemptionRepo.markRedeemed(
    redemptionId: id,
    redeemedByUserId: userId,
    barberBrandId: brandId,
  );
  if (!context.mounted) return;
  await redeemResult.fold(
    (f) async {
      showErrorSnackBar(context, message: f.message);
    },
    (_) async {
      lastScannedId.value = null;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Text(context.l10n.dashboardRedeemReward),
              content: Text(context.l10n.redeemSuccess),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    },
  );
}

const _scanCooldownDuration = Duration(seconds: 5);

Future<void> _handleLoyaltyPoints(
  BuildContext context,
  WidgetRef ref,
  String userId,
  ValueNotifier<String?> lastScannedId,
  ValueNotifier<DateTime?> lastFailedScanTime,
) async {
  _log.d('Loyalty: resolving user id="$userId"');
  final userRepo = ref.read(userRepositoryProvider);
  final appointmentRepo = ref.read(booking_di.appointmentRepositoryProvider);
  final bookingTransaction = ref.read(booking_di.bookingTransactionProvider);

  final userResult = await userRepo.getById(userId);
  UserEntity? user;
  userResult.fold(
    (f) {
      _log.w('Loyalty: getById failed', error: f.message);
      if (context.mounted) showErrorSnackBar(context, message: f.message);
    },
    (u) {
      user = u;
      _log.d('Loyalty: getById ok user=${u?.userId} fullName=${u?.fullName}');
    },
  );
  if (user == null || !context.mounted) {
    lastScannedId.value = null;
    lastFailedScanTime.value = DateTime.now();
    if (context.mounted) showErrorSnackBar(context, message: 'Invalid QR code');
    return;
  }

  final dashboardBrandId = ref.read(dashboard_di.dashboardBrandIdProvider);
  final configBrandId =
      ref.read(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId =
      dashboardBrandId.isNotEmpty
          ? dashboardBrandId
          : (configBrandId.isNotEmpty ? configBrandId : fallbackBrandId);

  final activeApptResult = await appointmentRepo
      .getActiveScheduledAppointmentForUser(userId, brandId);
  AppointmentEntity? appointment;
  activeApptResult.fold(
    (f) {
      _log.w(
        'Loyalty: getActiveScheduledAppointmentForUser failed',
        error: f.message,
      );
    },
    (a) => appointment = a,
  );

  if (appointment == null || !context.mounted) {
    lastScannedId.value = null;
    lastFailedScanTime.value = DateTime.now();
    if (context.mounted) {
      showErrorSnackBar(
        context,
        message: 'No active appointment for this customer',
      );
    }
    return;
  }

  int pointsMultiplier = 10;
  final brandRepo = ref.read(brandRepositoryProvider);
  final brandResult = await brandRepo.getById(brandId);
  brandResult.fold((_) {}, (brand) {
    if (brand != null) pointsMultiplier = brand.loyaltyPointsMultiplier;
  });

  final pointsToAdd = (appointment!.totalPrice * pointsMultiplier)
      .round()
      .clamp(0, 0x7fffffff);

  final result = await bookingTransaction.completeVisitAndAwardLoyaltyPoints(
    userId: userId,
    brandId: brandId,
    appointmentId: appointment!.appointmentId,
    pointsToAdd: pointsToAdd,
  );

  if (!context.mounted) return;
  await result.fold(
    (f) async {
      showErrorSnackBar(context, message: f.message);
      lastScannedId.value = null;
      lastFailedScanTime.value = DateTime.now();
    },
    (_) async {
      lastScannedId.value = null;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => _ScanSuccessDialog(
              customerName: user!.fullName,
              pointsAwarded: pointsToAdd,
            ),
      );
    },
  );
}

/// Barber scans customer QR: reward redemption or loyalty card (user id).
class RedeemRewardScanPage extends HookConsumerWidget {
  const RedeemRewardScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(isStaffProvider);
    final controller = useMemoized(() => MobileScannerController());
    final isProcessing = useState(false);
    final lastScannedId = useState<String?>(null);
    final lastFailedScanTime = useState<DateTime?>(null);

    useEffect(() {
      return () => controller.dispose();
    }, []);

    if (!isStaff) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return Scaffold(
        backgroundColor: context.appColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            context.l10n.dashboardRedeemReward,
            style: context.appTextStyles.bold.copyWith(
              color: context.appColors.primaryTextColor,
            ),
          ),
          backgroundColor: context.appColors.backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: context.appColors.primaryTextColor,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: const _AccessRestrictedPlaceholder(),
      );
    }

    Future<void> onDetect(BarcodeCapture capture) async {
      if (isProcessing.value) return;
      final failedAt = lastFailedScanTime.value;
      if (failedAt != null) {
        final elapsed = DateTime.now().difference(failedAt);
        if (elapsed < _scanCooldownDuration) {
          final remaining = _scanCooldownDuration.inSeconds - elapsed.inSeconds;
          if (context.mounted) {
            showErrorSnackBar(
              context,
              message: 'Please wait $remaining seconds before scanning again',
            );
          }
          return;
        }
        lastFailedScanTime.value = null;
      }
      final barcodes = capture.barcodes;
      if (barcodes.isEmpty) return;
      final raw = barcodes.first.rawValue?.trim();
      if (raw == null || raw.isEmpty) return;
      if (raw == lastScannedId.value) return;

      lastScannedId.value = raw;
      isProcessing.value = true;

      try {
        final redemptionRepo = ref.read(redemptionRepositoryProvider);
        final redemptionResult = await redemptionRepo.getById(raw);

        await redemptionResult.fold(
          (f) async {
            final parts = raw.split(':');
            final userId = parts.first.trim();
            await _handleLoyaltyPoints(
              context,
              ref,
              userId,
              lastScannedId,
              lastFailedScanTime,
            );
          },
          (redemption) async {
            if (redemption != null &&
                redemption.status == RedemptionStatus.pending) {
              await _handleRewardRedemption(
                context,
                ref,
                raw,
                redemption,
                redemptionRepo,
                lastScannedId,
              );
              return;
            }
            final parts = raw.split(':');
            final userId = parts.first.trim();
            await _handleLoyaltyPoints(
              context,
              ref,
              userId,
              lastScannedId,
              lastFailedScanTime,
            );
          },
        );
      } finally {
        if (context.mounted) isProcessing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          context.l10n.dashboardRedeemReward,
          style: context.appTextStyles.bold.copyWith(
            color: context.appColors.primaryTextColor,
          ),
        ),
        backgroundColor: context.appColors.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.appColors.primaryTextColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),
          if (isProcessing.value) const _ProcessingOverlay(),
          const _ScanViewfinder(),
        ],
      ),
    );
  }
}

class _AccessRestrictedPlaceholder extends StatelessWidget {
  const _AccessRestrictedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Access restricted',
        style: context.appTextStyles.medium.copyWith(
          color: context.appColors.secondaryTextColor,
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(context.appSizes.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: context.appSizes.paddingMedium),
                Text(
                  'Processing…',
                  style: context.appTextStyles.medium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanViewfinder extends StatelessWidget {
  const _ScanViewfinder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ScanSuccessDialog extends StatelessWidget {
  const _ScanSuccessDialog({
    required this.customerName,
    required this.pointsAwarded,
  });

  final String customerName;
  final int pointsAwarded;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      contentPadding: EdgeInsets.fromLTRB(24, 28, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: colors.primaryColor,
              size: 36,
            ),
          ),
          SizedBox(height: 20),
          Text(
            context.l10n.scanPointsAwardedTitle,
            style: context.appTextStyles.h3.copyWith(
              color: colors.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            context.l10n.scanPointsAwardedMessage(customerName, pointsAwarded),
            style: context.appTextStyles.body.copyWith(
              color: colors.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemConfirmDialog extends StatelessWidget {
  const _RedeemConfirmDialog({
    required this.rewardName,
    required this.pointsSpent,
  });

  final String rewardName;
  final int pointsSpent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.dashboardRedeemReward),
      content: Text(
        'Redeem "$rewardName" ($pointsSpent ${context.l10n.loyaltyPointsAbbrev})?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.loyaltyRedeem),
        ),
      ],
    );
  }
}
