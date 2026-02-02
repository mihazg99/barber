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

## 7. `appointments` (Collection)

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

---

## Code references

- **Collection names:** `lib/core/firebase/collections.dart`
- **Entities & mappers:**  
  - Brand → `features/brand/`  
  - Locations → `features/locations/`  
  - Services → `features/services/`  
  - Barbers → `features/barbers/`  
  - Users → `features/auth/`  
  - Availability & Appointments → `features/booking/`  
- **Working hours value type:** `lib/core/value_objects/working_hours.dart`

---

## Barber shift summary

| Stored in Firestore? | Where | Format |
|----------------------|--------|--------|
| **Shop hours** (default for all barbers) | `locations/{id}.working_hours` | Map: `mon`–`sun` → `{ open, close }` or `null` |
| **Barber shift** (optional override) | `barbers/{id}.working_hours_override` | Same map; overrides location for that barber |

**Not in schema (yet):** date-specific shifts, time-off, or swap shifts (would require e.g. a `shifts` or `time_off` collection).
