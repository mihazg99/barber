# Whitelabel Config Architecture

This document describes how to configure and generate multiple barber shop apps from the same codebase.

## Flavors vs Remote Config

| Approach | Use case | Pros | Cons |
|----------|----------|------|------|
| **Flavors** | Generate separate apps per client (each with own package ID, store listing, icon) | Build-time config, no network, clean CI/CD templates | New build needed to change branding |
| **Remote Config** | One app, change branding without release | Update without app update, A/B testing | Requires network, cache complexity, not for app store differentiation |
| **Firestore Brand** | Multi-tenant: one app, users see their brand after login | Already in your schema (`brands` collection) | Requires auth first; splash/loading needs fallback |

### Recommendation: Flavors + local config

For "generate these apps like a template", use **Flavors** with a **JSON config file per flavor**. Each barber brand (client) gets:

- Own entry point (e.g. `main_client_foo.dart`)
- Own config file (`config/client_foo.json`)
- Own Android flavor → different `applicationId`, `resValue` for app name
- Own iOS scheme → different bundle ID, display name
- **Own Firebase project** — one Firebase project per brand (not multi-tenant). See [FlutterFire configuration](#flutterfire-configuration) below.

Optional: Add **Firestore Brand** overlay later for post-login branding (logo URL, primary color from Firestore).

---

## Config structure

Each flavor has a JSON config in `assets/config/{flavor}.json`:

```json
{
  "app_title": "Old School Barber",
  "logo_path": "assets/branding/default_logo.png",
  "default_brand_id": "old-school-barber",
  "font_family": "Poppins",
  "colors": {
    "primary": "#6B63FF",
    "secondary": "#2A2F4A",
    "background": "#1E2235",
    "navigation_background": "#1A1D2E",
    "primary_text": "#FFFFFF",
    "secondary_text": "#D1D5E0",
    "caption_text": "#94A3B8",
    "error": "#B00020"
  }
}
```

---

## Adding a new client (template generation)

1. Create `assets/config/client_name.json` with branding.
2. Add logo to `assets/branding/client_name/` (e.g. `logo.png`, `logo@2x.png`).
3. Create `lib/main_client_name.dart` that initializes `FlavorConfig` with `client_name`.
4. Add Android flavor in `android/app/build.gradle.kts`.
5. Add iOS scheme in Xcode.
6. Build: `flutter build apk --flavor client_name -t lib/main_client_name.dart`

---

## CI/CD example

```bash
# Dev
flutter run --flavor default -t lib/main_dev.dart

# Prod
flutter run --flavor default -t lib/main_prod.dart

# Build release APK
flutter build apk --flavor default -t lib/main_prod.dart
```

## iOS flavors (schemes)

To add iOS schemes for different flavors:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Duplicate the Runner target (e.g. Runner-ClientFoo).
3. Create a new scheme that uses the new target.
4. Set different bundle ID and display name per scheme.

---

## FlutterFire configuration

Firebase is initialized via `lib/core/firebase/firebase_app.dart`, which uses the generated `lib/firebase_options.dart`. That file is created and updated by the FlutterFire CLI.

### Prerequisites

1. **Firebase CLI** (if not installed):
   ```bash
   npm install -g firebase-tools
   ```
2. **Log in to Firebase** (once per machine):
   ```bash
   firebase login
   ```
3. **FlutterFire CLI** is used via Dart; no separate install. Ensure dependencies are installed:
   ```bash
   flutter pub get
   ```

**Model:** Each barber brand (whitelabel) has its **own Firebase project**. The app is not multi-tenant; when you build for a given brand, that build talks only to that brand’s Firebase project. `lib/firebase_options.dart` holds the config for one Firebase project at a time.

### Default project (first-time / dev setup)

Use this for the **default** flavor (e.g. “Barber” dev/prototype). One Firebase project is linked to the repo at a time via `firebase_options.dart`.

**Default flavor app IDs (enter these when adding apps in Firebase Console):**

| Platform | Firebase Console field | Value |
|----------|------------------------|--------|
| Android  | Android package name   | `com.tamebooking.app` |
| iOS      | Bundle ID              | `com.tamebooking.app` |

1. In [Firebase Console](https://console.firebase.google.com/), create a project (or select an existing one) for this brand.
2. Add Android and iOS apps in that project using the values above (from `android/app/build.gradle.kts` and `ios/Runner.xcodeproj`).
3. Download and place config files if the CLI does not do it:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. From the **project root**:
   ```bash
   dart run flutterfire_cli:flutterfire configure
   ```
5. Select this Firebase project and the platforms (e.g. Android, iOS). This generates/overwrites `lib/firebase_options.dart` and creates/updates `.firebaserc`.

**Commit:** You can commit `lib/firebase_options.dart` and `.firebaserc` for the default/dev brand so the team has a working setup. Add `google-services.json` and `GoogleService-Info.plist` to `.gitignore` if you prefer not to commit them; the CLI expects them in the paths above.

### After clone or new machine (default brand)

If the repo already has `firebase_options.dart` for the default project:

1. `firebase login`
2. `dart run flutterfire_cli:flutterfire configure` and select the same Firebase project.

If native config files are not in the repo, add the apps in Firebase Console, download `google-services.json` and `GoogleService-Info.plist` to the paths above, then run `flutterfire configure` again.

### Adding a new barber brand (new Firebase project)

Each new brand gets its own Firebase project and its own app build. Use one of these workflows.

**Option A – Separate clone / build pipeline per brand (recommended for release builds)**

1. Create a new Firebase project in [Firebase Console](https://console.firebase.google.com/) for the brand.
2. Add Android and iOS apps with that brand’s application ID and bundle ID (from the flavor you added for the client).
3. In a **dedicated clone or CI job** for that brand:
   - Check out the repo (or use a clean workspace).
   - Run `dart run flutterfire_cli:flutterfire configure` and select the **brand’s** Firebase project.
   - Build: `flutter build apk --flavor client_foo -t lib/main_client_foo.dart` (or the equivalent for that client).

That clone/job now has `firebase_options.dart` pointing at that brand’s Firebase only. Do not commit that file from brand-specific pipelines if the repo is shared; treat it as build-time input, or use a separate repo/branch per brand.

**Option B – Same repo, switch project when building a brand**

1. Create the Firebase project and add Android/iOS apps for the brand (as above).
2. On your machine, run `dart run flutterfire_cli:flutterfire configure` and select the **brand’s** Firebase project (overwrites `lib/firebase_options.dart`).
3. Build for that brand: `flutter build apk --flavor client_foo -t lib/main_client_foo.dart`.
4. When switching back to default/dev, run `flutterfire configure` again and select the default Firebase project.

**CI:** For Option A, use a CI secret or env (e.g. `FIREBASE_PROJECT`) and run `flutterfire configure` in the job so the generated `firebase_options.dart` matches the brand being built.

### When to re-run `flutterfire configure`

- First-time setup or after clone (default project).
- You add a new platform (e.g. web) to a Firebase project and need it in `firebase_options.dart`.
- You are about to build for a different brand (switch to that brand’s Firebase project).
- You created a new Firebase project for a new brand and are wiring this app to it.

### Quick reference

```bash
# Default / dev project (from project root)
firebase login
dart run flutterfire_cli:flutterfire configure

# Result: lib/firebase_options.dart and .firebaserc point at one Firebase project.
# App uses DefaultFirebaseOptions.currentPlatform in lib/core/firebase/firebase_app.dart.
# Each barber brand = separate Firebase project; switch or generate firebase_options per brand build.
```
