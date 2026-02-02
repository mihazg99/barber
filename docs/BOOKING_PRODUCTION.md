# Booking & time-slot logic – production readiness

Summary of what is production-ready and what to consider for a barber salon.

---

## What is production-ready

- **Slot calculation**
  - Working hours (location + optional barber override), slot interval (15/30 min), service duration, and buffer time are all respected.
  - In-between start times: after a booking (e.g. 25 min ending at 08:40), the next offered time is 08:40 + buffer, not only the next grid time (08:45), so no unnecessary gaps.
  - Overlap check: a slot is only shown if it fits before closing and does not overlap any existing booking + buffer.

- **Atomic booking**
  - Creating an appointment and updating the availability document (marking the slot as booked) is done in a **single Firestore transaction** (`BookingTransaction.createBookingWithSlot`).
  - Two users cannot book the same slot: the second transaction sees the updated availability and fails with “slot taken”.
  - No orphan appointments: if the transaction fails, neither the appointment nor the availability update is committed.

- **Double-booking prevention**
  - Per-user: the app blocks booking a second upcoming appointment until the first is cancelled or completed.
  - Per-slot: the transaction checks that the slot is still free before writing.

- **Debug logging**
  - Availability/slot debug prints are gated with `kDebugMode` so they do not run in release builds.

---

## Considerations for production

1. **Timezone**
   - Working hours and slot times are stored as **local-time strings** (e.g. `"08:00"`, `"20:00"`). The app uses the device date/time for “today” and weekday (e.g. `date.weekday` for mon–sun).
   - For a **single-location salon in one timezone**, this is usually fine: everyone books in “salon time.”
   - For **multiple timezones** (e.g. chain with shops in different countries), you’d want to define the salon’s timezone and convert “now” / selected date to that timezone before computing slots and storing appointment times.

2. **Cancellation**
   - When a user cancels an appointment, the corresponding slot should be removed from the availability document’s `booked_slots` so it becomes bookable again. That flow is not implemented yet; add it and run it (or a transaction) so appointment status and availability stay in sync.

3. **Firestore rules**
   - Appointments: `update, delete: if false` – users cannot cancel or update from the app until you add a rule (e.g. allow update of `status` to `cancelled` for own document).
   - Availability: read + create/update are allowed for signed-in users; adjust if you want only backend or admin to write.

4. **Rate limiting / abuse**
   - Firestore does not enforce rate limits. For high traffic, consider App Check and/or backend validation for booking creation.

5. **Past availability docs**
   - Over time you may want to archive or delete old `availability/{barber_id_YYYY-MM-DD}` documents to keep the collection small. This is operational, not required for correctness.

---

## Code references

- Slot calculation: `lib/features/booking/domain/use_cases/calculate_free_slots.dart`
- Atomic create + update: `lib/features/booking/data/services/booking_transaction.dart`
- Booking flow: `lib/features/booking/presentation/pages/booking_page.dart` (uses `bookingTransactionProvider`)
