# Core Firebase

**Clean architecture:** This folder holds only **shared Firebase infrastructure**, not domain entities.

- **`firebase_app.dart`** – Firebase initialization (call before `runApp`).
- **`collections.dart`** – Firestore collection name constants. Used by feature **data** layers (datasources/repositories).

**Where entities live:** Each feature owns its own domain and data layer:

- **Brand** → `features/brand/domain/entities/` + `features/brand/data/mappers/`
- **Locations** → `features/locations/...`
- **Services** → `features/services/...`
- **Barbers** → `features/barbers/...`
- **Auth (user)** → `features/auth/...`
- **Booking** → `features/booking/...` (availability, appointment, booked_slot)

**Shared value types** used by multiple features (e.g. working hours) live in **`core/value_objects/`**.

Domain entities are **pure Dart** (no Firestore imports). Firestore ↔ entity mapping is done in each feature’s **data/mappers/** (e.g. `BrandFirestoreMapper`).
