# Firestore Database Structure

Barbershop whitelabel app – final Firestore schema. Collection names are defined in `lib/core/firebase/collections.dart`.

---

## 1. `brands` (Collection)

Root configuration for each client (brand).

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `brand_id` (e.g. `old-school-barber`) |
| `name` | String | Brand display name (e.g. "Old School Barber") |
| `is_multi_location` | Boolean | Whether the brand has multiple shops |
| `primary_color` | String | Hex color (e.g. `"#0A0A0A"`) |
| `logo_url` | String | URL of brand logo |
| `contact_email` | String | Contact email |
| `slot_interval` | Number | Slot length in minutes (e.g. 15 or 30) |
| `buffer_time` | Number | Minutes between appointments (e.g. 5) |
| `cancel_hours_minimum` | Number | Min hours before appointment that cancellation is allowed (e.g. 48 = must cancel ≥48h ahead; 0 = anytime) |
| `loyalty_points_multiplier` | Number | Points per 1€ when barber scans loyalty QR (e.g. 10 = 30€ → 300 points; default 10) |

---

## 2. `locations` (Collection)

Specific shops belonging to a brand.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `location_id` (e.g. `zagreb-centar`) |
| `brand_id` | String | Reference to brand document |
| `name` | String | Shop name (e.g. "OSB - Centar") |
| `address` | String | Full address |
| `geo_point` | Geopoint | Latitude and longitude |
| `phone` | String | Phone number |
| `working_hours` | Map | See [Working hours](#working-hours-map) below |

### Working hours (Map)

Keys: `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`.  
Value per day: `{ "open": "08:00", "close": "20:00" }` or `null` if closed.

---

## 3. `services` (Collection)

Services offered by the brand.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `service_id` |
| `brand_id` | String | Reference to brand |
| `available_at_locations` | Array\<String\> | List of `location_id`s where this service is offered |
| `name` | String | Service name (e.g. "Šišanje & Pranje") |
| `price` | Number | Price |
| `duration_minutes` | Number | Duration in minutes |
| `description` | String | Optional description |

---

## 4. `barbers` (Collection)

Employees assigned to specific locations.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `barber_id` |
| `brand_id` | String | Reference to brand |
| `location_id` | String | Reference to location (shop) |
| `name` | String | Barber display name |
| `photo_url` | String | URL of barber photo |
| `active` | Boolean | Whether the barber is active |
| `working_hours_override` | Map (optional) | **Barber shift.** Same format as location [working hours](#working-hours-map); overrides location hours for this barber. When absent, barber is assumed to work the location’s hours. |

### Barber–user linking

Add `user_id` (String, optional) to link a barber record to the Firebase Auth user who logs in. When a barber signs in, the app fetches `barbers` where `user_id == their UID`. Set via Admin SDK when assigning barber role:

```js
await admin.firestore().collection('barbers').doc(barberId).update({ user_id: authUid });
```

### Where is barber shift stored?

**Barber shift = when a barber can take appointments.**

- **Default:** Use the **location’s** `working_hours` (barber works whenever the shop is open).
- **Override:** Set **barber’s** `working_hours_override` (e.g. only Tue–Sat 09:00–17:00).

There is **no** separate `shifts` collection. Shifts are:

1. **Location** `working_hours` → shop’s recurring weekly schedule (default for all barbers at that location).
2. **Barber** `working_hours_override` → that barber’s recurring weekly schedule (optional).

Both are **recurring by weekday** (mon–sun). There is no date-specific shift (e.g. “Luka off on 2026-02-05”) in the current schema.

---

## 5. `users` (Collection)

App users (clients). Document ID = Firebase Auth UID.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `user_uid` (Firebase Auth UID) |
| `full_name` | String | User full name |
| `phone` | String | Phone number |
| `fcm_token` | String | FCM token for push notifications |
| `brand_id` | String | Brand the user belongs to |
| `loyalty_points` | Number | Single loyalty card: points for this user (brand) |
| `role` | String | One of: `user`, `barber`, `superadmin`. Default `user`. **Security:** Clients can only create/keep `user`. `barber` and `superadmin` must be assigned via Firebase Admin SDK (Cloud Functions, admin tool). |
| `barber_id` | String (optional) | When `role == 'barber'`, set to the **barbers** document id (e.g. `luka`) so security rules can allow the barber to read appointments where they are assigned. Required for barber dashboard “upcoming appointments” to work. |

### Role-based navigation

- **`user`** → Main app (home, booking, loyalty)
- **`barber`** → Dashboard (staff view)
- **`superadmin`** → Dashboard (staff view)

### Assigning barber/superadmin roles

Role is stored in Firestore `users/{uid}.role`. Client app cannot set `barber` or `superadmin` due to security rules. Use Firebase Admin SDK to update the document (bypasses rules):

```js
const admin = require('firebase-admin');
await admin.firestore().collection('users').doc(uid).update({ role: 'barber' });
// or { role: 'superadmin' }
// When assigning barber, also set barber_id to the barbers document id so the barber can read their assigned appointments:
await admin.firestore().collection('users').doc(uid).update({ role: 'barber', barber_id: barberDocId });
```

---

## 6. `availability` (Collection)

Pre-calculated slots for fast booking (“engine” for booking).

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `barber_id_YYYY-MM-DD` (e.g. `luka_2026-05-10`) |
| `barber_id` | String | Reference to barber |
| `location_id` | String | Reference to location |
| `date` | String | Date in `YYYY-MM-DD` format |
| `booked_slots` | Array\<Map\> | List of booked slots; each item: `{ "start": "08:00", "end": "08:35", "appointment_id": "abc-123" }` |

---

## 7. `user_booking_locks` (Collection)

Enforces one active appointment per user. One document per user.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `user_id` (Firebase Auth UID) |
| `user_id` | String | Same as doc_id |
| `active_appointment_id` | String | ID of user's current scheduled (future) appointment |

Used atomically in booking transactions. When creating an appointment, the transaction reads this doc and, if it points to a still-active appointment, fails. After creating, it updates this doc with the new appointment id.

**Migration:** For existing users who had appointments before this collection existed, run a one-time script to populate `active_appointment_id` for each user who has a scheduled, future appointment.

---

## 8. `appointments` (Collection)

Detailed records of all bookings.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `appointment_id` |
| `brand_id` | String | Reference to brand |
| `location_id` | String | Reference to location |
| `user_id` | String | Reference to user (client) |
| `barber_id` | String | Reference to barber |
| `service_ids` | Array\<String\> | List of service IDs included in the appointment |
| `start_time` | Timestamp | Appointment start |
| `end_time` | Timestamp | Appointment end |
| `total_price` | Number | Total price |
| `status` | String | One of: `scheduled`, `completed`, `cancelled`, `no_show` |
| `created_at` | ServerTimestamp | Set on create (use `FieldValue.serverTimestamp()`) |
| `no_show_counted` | Boolean (optional) | Set by Cloud Function when no_show stats aggregated (idempotency) |

---

## 9. `rewards` (Collection)

Loyalty rewards catalog per brand. Redeemable items with a points cost.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `reward_id` |
| `brand_id` | String | Reference to brand |
| `name` | String | Reward name (e.g. "Free haircut") |
| `description` | String | Optional description |
| `points_cost` | Number | Points required to redeem |
| `sort_order` | Number | Display order (default 0) |
| `is_active` | Boolean | If false, hidden from catalog (default true) |

**Security:** Read for any signed-in user. Create/update/delete for superadmin only.

---

## 10. `reward_redemptions` (Collection)

User spent points to "buy" a reward. Document ID is encoded in the QR code the customer shows at the barber; barber scans to mark the reward as redeemed.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `redemption_id` (use in QR payload) |
| `user_id` | String | User who claimed the reward |
| `reward_id` | String | Reference to reward |
| `brand_id` | String | Brand (must match barber’s brand to redeem) |
| `reward_name` | String | Denormalized for display when scanning |
| `points_spent` | Number | Points deducted |
| `status` | String | `pending` (not yet used) or `redeemed` (barber fulfilled) |
| `created_at` | ServerTimestamp | When user claimed |
| `redeemed_at` | Timestamp (optional) | When barber scanned and redeemed |
| `redeemed_by` | String (optional) | User ID of barber who redeemed |

**Flow:** Client app runs a transaction: read `users/{uid}` (check points), create this doc with `status: pending`, update user’s `loyalty_points`. Barber app scans QR (doc id), looks up doc, confirms brand and `status == pending`, then updates doc with `status: redeemed`, `redeemed_at`, `redeemed_by`.

**Security:** User can create only with `user_id == request.auth.uid`. User can read own redemptions. Barber/superadmin can read any and update only when `resource.data.brand_id == barberBrandId()` and `resource.data.status == 'pending'`.

---

## 11. `daily_stats` (Subcollection under locations)

Pre-aggregated daily metrics per location. Path: `locations/{location_id}/daily_stats/{YYYY-MM-DD}`. Updated by Cloud Function `onBookingComplete` when appointments complete or are marked no_show.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `YYYY-MM-DD` (date key) |
| `total_revenue` | Number | Sum of completed appointment prices |
| `appointments_count` | Number | Count of completed appointments |
| `new_customers` | Number | Count of first-time completers (lifetime_value was 0) |
| `no_shows` | Number | Count of no-show appointments |
| `service_breakdown` | Map\<String, int\> | service_id → count of appointments including that service |

---

## 12. `monthly_stats` (Subcollection under locations)

Pre-aggregated monthly metrics per location. Path: `locations/{location_id}/monthly_stats/{YYYY-MM}`. Updated by Cloud Function `onBookingComplete` when appointments complete.

| Field | Type | Description |
|-------|------|-------------|
| **doc_id** | — | `YYYY-MM` (month key) |
| `total_revenue` | Number | Sum of completed appointment prices |
| `top_barber_id` | String (optional) | Barber with most appointments (computed client-side from barber_appointments) |
| `retention_rate` | Number (optional) | 0.0–1.0, computed by batch job |
| `barber_appointments` | Map\<String, int\> | barber_id → appointment count |

---

## Security rules (firestore.rules)

Rules are tuned to avoid **dependency storms** and deny spikes during login/logout:

- **Reads are decoupled from role checks:** No `get()` (user document lookup) is used on any **read** path. Public collections (`brands`, `locations`, `barbers`, `services`, `availability`, `rewards`) allow read for any authenticated user. Private data (`users`, `appointments`, `user_booking_locks`, `reward_redemptions`) use strict **userId matching only** for reads (e.g. `request.auth.uid == userId` or `resource.data.user_id == request.auth.uid`), so no role lookup is needed.
- **Writes stay strict:** All create/update/delete that require elevated access still use `isSuperadmin()` or `isBarberOrSuperadmin()` (and `barberBrandId()` where needed), so those rules perform a single `get()` only when a write is evaluated.
- **Private data:** Users can only read/write their own `users` doc, their own appointments, their own `user_booking_locks` doc, and their own `reward_redemptions`. Barbers/superadmins need backend (e.g. Admin SDK) to read other users’ data; client rules do not allow role-based read escalation to avoid get() on every read.

## Code references

- **Collection names:** `lib/core/firebase/collections.dart`
- **Entities & mappers:**  
  - Brand → `features/brand/`  
  - Locations → `features/locations/`  
  - Services → `features/services/`  
  - Barbers → `features/barbers/`  
  - Users → `features/auth/`  
  - Availability & Appointments → `features/booking/`  
  - Rewards & Redemptions → `features/rewards/`  
  - Stats (daily_stats, monthly_stats) → `features/stats/`  
- **Working hours value type:** `lib/core/value_objects/working_hours.dart`

---

## Barber shift summary

| Stored in Firestore? | Where | Format |
|----------------------|--------|--------|
| **Shop hours** (default for all barbers) | `locations/{id}.working_hours` | Map: `mon`–`sun` → `{ open, close }` or `null` |
| **Barber shift** (optional override) | `barbers/{id}.working_hours_override` | Same map; overrides location for that barber |

**Not in schema (yet):** date-specific shifts, time-off, or swap shifts (would require e.g. a `shifts` or `time_off` collection).
