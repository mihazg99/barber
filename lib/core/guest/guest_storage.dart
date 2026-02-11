import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Keys for guest-related data in SharedPreferences.
abstract final class GuestStorageKeys {
  static const String guestId = 'guest_id';
  static const String bookingDraft = 'booking_draft';
  static const String guestBrands = 'guest_brands';
}

/// Persists and reads a stable guest ID and optional booking draft.
class GuestStorage {
  GuestStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  /// Returns the existing guest ID or creates and persists a new one.
  String getOrCreateGuestId() {
    var id = _prefs.getString(GuestStorageKeys.guestId);
    if (id == null || id.isEmpty) {
      id = 'guest_${_uuid.v4()}';
      _prefs.setString(GuestStorageKeys.guestId, id);
    }
    return id;
  }

  /// Clears guest ID (e.g. after sign-in if we want to stop treating as guest).
  void clearGuestId() {
    _prefs.remove(GuestStorageKeys.guestId);
  }

  /// Saves booking draft JSON (guest tapped confirm; will restore after sign-in).
  void setBookingDraftJson(String? json) {
    if (json == null || json.isEmpty) {
      _prefs.remove(GuestStorageKeys.bookingDraft);
    } else {
      _prefs.setString(GuestStorageKeys.bookingDraft, json);
    }
  }

  /// Reads booking draft JSON, or null if none.
  String? getBookingDraftJson() =>
      _prefs.getString(GuestStorageKeys.bookingDraft);

  /// Clears booking draft after successful restore or booking.
  void clearBookingDraft() {
    _prefs.remove(GuestStorageKeys.bookingDraft);
  }

  /// Adds a brand ID to the list of guest brands (if not already present).
  void addGuestBrand(String brandId) {
    final brands = getGuestBrands();
    if (!brands.contains(brandId)) {
      brands.add(brandId);
      _prefs.setStringList(GuestStorageKeys.guestBrands, brands);
    }
  }

  /// Returns the list of brand IDs the guest has previously selected.
  List<String> getGuestBrands() {
    return _prefs.getStringList(GuestStorageKeys.guestBrands) ?? [];
  }

  /// Clears the list of guest brands (e.g. after sign-in if migrating to user_brands).
  void clearGuestBrands() {
    _prefs.remove(GuestStorageKeys.guestBrands);
  }
}
