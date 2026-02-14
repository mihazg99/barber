# Deep links (Unified Entry Point)

Both **Universal/App Links** and **FCM notification taps** are normalized into a single routing stream and drive GoRouter navigation.

## Flow

1. **Entry points**
   - **App link (in app):** `AppLinks().uriLinkStream` → `DeepLinkNotifier` sets pending path.
   - **App link (cold start):** `_DeepLinkHandler` (in `lib/app.dart`) calls `AppLinks().getInitialLink()` → notifier `setPendingFromInitialLink(uri)`.
   - **FCM tap (background):** `FirebaseMessaging.onMessageOpenedApp` → notifier sets pending path.
   - **FCM tap (cold start):** `_DeepLinkHandler` calls `getInitialMessage()` → notifier `setPendingFromInitialMessage(message)`.

2. **Normalization**  
   URL or FCM `data` is converted to an `AppPath` (path + queryParams + optional brandId) in `DeepLinkNotifier`.

3. **Navigation**  
   `goRouterProvider` (in `app_router.dart`) listens to `deepLinkNotifierProvider`. When there is a pending path it:
   - Sets `lockedBrandIdProvider` if `path.brandId` is present (so auth/brand guards are satisfied).
   - Calls `goRouter.go(path.location)`.
   - Calls `consumePending()`.

## Where the handler runs

**\_DeepLinkHandler** is mounted in **MyApp** so it runs on every app launch:

- **File:** `lib/app.dart`
- **Place:** Inside `MaterialApp.router(..., builder: ...)`: the `Stack` has `Positioned.fill(child: _DeepLinkHandler())` as the first overlay (before `LoginOverlay`). The handler renders nothing (`SizedBox.shrink`) and runs a one-shot effect to feed initial link and initial FCM message into the deep link notifier.
- **Role:** On first build it runs once (via `useEffect`): after a short delay it feeds `getInitialLink()` and `getInitialMessage()` into `DeepLinkNotifier`. Without this, cold-start links (app opened from a link or from a notification) would not be applied.

## Core user routes

Defined in `DeepLinkRoutes`. Use these for URLs and FCM payloads.

| Route             | Path                          | FCM `type`        | Params / FCM keys                          |
|------------------|-------------------------------|-------------------|--------------------------------------------|
| **Manage booking** | `/manage_booking/:appointmentId` | `manage_booking`   | `appointmentId`, `brandId`                 |
| **Create booking** | `/booking`                    | `booking` / `book` | `brandId`, `barberId`, `serviceId`, `locationId` |
| **Rewards**        | `/loyalty`                    | `rewards` / `loyalty` | `brandId`                               |

### Universal/App Link URL examples

- Manage: `https://yourapp.com/manage_booking/abc123?brandId=xyz`
- Booking: `https://yourapp.com/booking?brandId=xyz&barberId=b1&serviceId=s1`
- Rewards: `https://yourapp.com/loyalty?brandId=xyz`

(Your configured scheme/host may differ; path and query params stay as above.)

### FCM data payload examples

Send these in `message.data` (e.g. from Cloud Functions or your backend):

- **Manage booking:**  
  `{ "type": "manage_booking", "appointmentId": "abc123", "brandId": "xyz" }`
- **Create booking:**  
  `{ "type": "booking", "brandId": "xyz", "barberId": "b1", "serviceId": "s1" }`
- **Rewards:**  
  `{ "type": "rewards", "brandId": "xyz" }` or `{ "type": "loyalty", "brandId": "xyz" }`

Optional: send a full path instead of `type` + ids:  
`{ "path": "/manage_booking/abc123?brandId=xyz" }`

## Building links in code

Use `DeepLinkRoutes` to build `AppPath` (e.g. for share links or when building FCM payloads):

```dart
// Manage booking
final path = DeepLinkRoutes.manageBooking('apt123', brandId: 'brand1');

// Create booking with pre-selected barber
final path = DeepLinkRoutes.createBooking(brandId: 'brand1', barberId: 'barber1');

// Rewards
final path = DeepLinkRoutes.rewards(brandId: 'brand1');
// path.location is the full path + query for GoRouter
```

## Auth and brand locking

- Router redirect logic (auth guard, onboarding, brand selection) runs as usual. A deep link triggers `go(path.location)`; if the user is not allowed on that route, the redirect may send them to auth/onboarding first.
- When the payload or URL includes `brandId`, the listener sets `lockedBrandIdProvider` before calling `go()`, so the correct brand context is applied before navigation.

## Files

| File | Purpose |
|------|--------|
| `app_path.dart` | `AppPath` record and `.location` for GoRouter. |
| `deep_link_routes.dart` | Core route constants and `DeepLinkRoutes` builders. |
| `deep_link_notifier.dart` | `DeepLinkNotifier`: streams + normalization. |
| `deep_link_di.dart` | `deepLinkNotifierProvider`. |
| `lib/app.dart` | `MyApp`; `_DeepLinkHandler` mounted in app builder Stack. |
| `lib/core/router/app_router.dart` | `goRouterProvider` listens to deep link notifier and navigates. |
