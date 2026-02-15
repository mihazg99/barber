import 'package:shared_preferences/shared_preferences.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _keyNotificationsEnabled = 'notifications_enabled';

/// Notifier for the user's notification preference (on/off).
/// Persisted in SharedPreferences; default is true.
class NotificationSettingsNotifier extends BaseNotifier<bool, dynamic> {
  NotificationSettingsNotifier(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  Future<void> _load() async {
    setLoading();
    try {
      final enabled = _prefs.getBool(_keyNotificationsEnabled) ?? true;
      setData(enabled);
    } catch (_) {
      setData(true);
    }
  }

  /// Toggles notifications on/off and persists the value.
  Future<void> setEnabled(bool enabled) async {
    try {
      await _prefs.setBool(_keyNotificationsEnabled, enabled);
      setData(enabled);
    } catch (e) {
      setError('Failed to save setting: $e', e);
    }
  }
}

final notificationSettingsNotifierProvider =
    StateNotifierProvider.autoDispose<
        NotificationSettingsNotifier,
        BaseState<bool>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs);
});
