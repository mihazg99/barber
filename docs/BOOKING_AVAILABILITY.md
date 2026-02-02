# Booking & Availability System

## Overview

The booking system calculates available time slots **on-the-fly** by combining:
1. **Working hours** (from location or barber override)
2. **Slot interval** (from brand configuration)
3. **Booked slots** (from Firestore `availability` collection)

## Architecture

### No Backend Processing Required

The system does **NOT** require:
- ❌ Pre-generation of availability documents
- ❌ Backend cron jobs
- ❌ Cloud functions to maintain availability

### How It Works

```
User selects date + barber
    ↓
System fetches:
1. Brand (for slot_interval, e.g., 15 or 30 minutes)
2. Location (for working_hours, e.g., 08:00-20:00)
3. Barber (for working_hours_override if exists)
4. Availability doc (optional: barber_id_YYYY-MM-DD)
    ↓
Calculate free slots:
1. Generate all slots from open to close (slot_interval steps)
2. Filter out booked_slots from availability doc (if exists)
3. Filter out slots too short for the service
    ↓
Display available times to user
```

## Firestore Data Requirements

### Required Data

#### 1. Brand Document
```json
{
  "brand_id": "old-school-barber",
  "slot_interval": 30,  // ← REQUIRED: 15 or 30 minutes
  "buffer_time": 5
}
```

#### 2. Location Document
```json
{
  "location_id": "zagreb-centar",
  "brand_id": "old-school-barber",
  "working_hours": {  // ← REQUIRED
    "mon": { "open": "08:00", "close": "20:00" },
    "tue": { "open": "08:00", "close": "20:00" },
    "wed": { "open": "08:00", "close": "20:00" },
    "thu": { "open": "08:00", "close": "20:00" },
    "fri": { "open": "08:00", "close": "20:00" },
    "sat": { "open": "09:00", "close": "17:00" },
    "sun": null  // Closed on Sunday
  }
}
```

#### 3. Barber Document
```json
{
  "barber_id": "luka",
  "brand_id": "old-school-barber",
  "location_id": "zagreb-centar",
  "name": "Luka",
  "active": true,  // ← REQUIRED: must be true
  "working_hours_override": null  // Optional: overrides location hours
}
```

#### 4. Service Document
```json
{
  "service_id": "haircut",
  "brand_id": "old-school-barber",
  "name": "Haircut",
  "duration_minutes": 30,  // ← REQUIRED for slot calculation
  "price": 25
}
```

### Optional Data

#### Availability Document (only needed when slots are booked)
```json
{
  "doc_id": "luka_2026-02-03",  // barber_id + YYYY-MM-DD
  "barber_id": "luka",
  "location_id": "zagreb-centar",
  "date": "2026-02-03",
  "booked_slots": [
    {
      "start": "09:00",
      "end": "09:30",
      "appointment_id": "abc-123"
    }
  ]
}
```

**If this document doesn't exist** → All slots are considered free!

## Troubleshooting "No Available Times"

### Checklist

1. **Check Brand has slot_interval:**
   ```
   brands/{brand_id}
   → slot_interval: 30 (or 15)
   ```

2. **Check Location has working_hours:**
   ```
   locations/{location_id}
   → working_hours.mon: { open: "08:00", close: "20:00" }
   ```

3. **Check Barber is active and at location:**
   ```
   barbers/{barber_id}
   → active: true
   → location_id: matches the location
   ```

4. **Check day of week:**
   - If working_hours.{weekday} is `null`, that day is closed
   - Example: If `working_hours.sun: null`, no slots on Sunday

5. **Check service duration fits:**
   - If service is 60 minutes and location closes at 20:00
   - Last slot will be 19:00 (not 19:30)

### Debug Provider

Add this to your booking page to debug:

```dart
// In booking_page.dart
@override
Widget build(BuildContext context) {
  final bookingState = ref.watch(bookingNotifierProvider);
  
  // Debug: Check what's missing
  if (bookingState.selectedDate != null) {
    ref.listen(availableTimeSlotsProvider, (prev, next) {
      next.when(
        data: (slots) => print('DEBUG: Found ${slots.length} slots'),
        loading: () => print('DEBUG: Loading slots...'),
        error: (err, stack) => print('DEBUG ERROR: $err'),
      );
    });
  }
  
  // ... rest of build
}
```

## When to Create Availability Documents

### Automatic Creation (Recommended)

When a user books an appointment, the system should:
1. Create/update the `availability` document
2. Add the booked slot to `booked_slots`

**Implementation needed in booking page:**

```dart
// After creating appointment
final availabilityDocId = '${barberId}_${dateStr}';
final availabilityResult = await availabilityRepository.get(availabilityDocId);

final availability = availabilityResult.fold(
  (_) => AvailabilityEntity(
    docId: availabilityDocId,
    barberId: barberId,
    locationId: locationId,
    date: dateStr,
    bookedSlots: [],
  ),
  (existing) => existing ?? /* create new */,
);

// Add new booked slot
final updatedSlots = [...availability.bookedSlots, BookedSlot(
  start: '09:00',
  end: '09:30',
  appointmentId: appointmentId,
)];

await availabilityRepository.set(availability.copyWith(bookedSlots: updatedSlots));
```

### Manual Seeding (For Testing)

Use the `SeedAvailability` use case to pre-populate empty availability documents:

```dart
final seeder = SeedAvailability(ref.read(availabilityRepositoryProvider));
await seeder.seedBarberAvailabilityForDays(
  barberId: 'luka',
  locationId: 'zagreb-centar',
  daysAhead: 14,
);
```

## Summary

✅ **System works without availability documents** (assumes all slots free)  
✅ **No backend processing required**  
✅ **Availability documents only track bookings**  
✅ **Working hours + slot interval = available times**  

🔧 **Most common issue:** Missing working_hours in location document
