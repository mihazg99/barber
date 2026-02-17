import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/booking/data/services/booking_transaction.dart';
import 'package:barber/features/booking/di.dart';
import 'package:barber/features/dashboard/di.dart';

final appointmentActionNotifierProvider = StateNotifierProvider.autoDispose<
  AppointmentActionNotifier,
  BaseState<void>
>((ref) {
  return AppointmentActionNotifier(
    ref.watch(bookingTransactionProvider),
    ref.watch(currentUserProvider).valueOrNull?.userId,
    ref.watch(dashboardBrandIdProvider),
    ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId,
  );
});

class AppointmentActionNotifier extends BaseNotifier<void, void> {
  AppointmentActionNotifier(
    this._bookingTransaction,
    this._currentUserId,
    this._dashboardBrandId,
    this._configBrandId,
  );

  final BookingTransaction _bookingTransaction;
  final String? _currentUserId;
  final String _dashboardBrandId;
  final String _configBrandId;

  Future<bool> markAsComplete(
    String appointmentId,
    String appointmentUserId,
  ) async {
    if (_currentUserId == null) {
      if (mounted) {
        setError('User not authenticated');
      }
      return false;
    }

    final brandId =
        _dashboardBrandId.isNotEmpty
            ? _dashboardBrandId
            : (_configBrandId.isNotEmpty ? _configBrandId : fallbackBrandId);

    if (mounted) {
      setLoading();
    }
    final result = await _bookingTransaction.markAsComplete(
      appointmentId: appointmentId,
      userId: appointmentUserId,
      brandId: brandId,
    );

    return result.fold(
      (failure) {
        if (mounted) {
          setError(failure.message);
        }
        return false;
      },
      (_) {
        if (mounted) {
          setData(null);
        }
        return true;
      },
    );
  }

  Future<bool> markAsNoShow(
    String appointmentId,
    String appointmentUserId,
  ) async {
    if (_currentUserId == null) {
      if (mounted) {
        setError('User not authenticated');
      }
      return false;
    }

    final brandId =
        _dashboardBrandId.isNotEmpty
            ? _dashboardBrandId
            : (_configBrandId.isNotEmpty ? _configBrandId : fallbackBrandId);

    if (mounted) {
      setLoading();
    }
    final result = await _bookingTransaction.markAsNoShow(
      appointmentId: appointmentId,
      userId: appointmentUserId,
      brandId: brandId,
    );

    return result.fold(
      (failure) {
        if (mounted) {
          setError(failure.message);
        }
        return false;
      },
      (_) {
        if (mounted) {
          setData(null);
        }
        return true;
      },
    );
  }
}
