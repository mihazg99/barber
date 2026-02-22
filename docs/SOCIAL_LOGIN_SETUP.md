# Social Login Setup Guide

This guide covers the configuration needed for Google Sign-In and Apple Sign-In to work in your Flutter app.

## Prerequisites

- Firebase project is already configured (`google-services.json` and `GoogleService-Info.plist` are present)
- Firebase Authentication is enabled in Firebase Console

## Google Sign-In Setup

### 1. Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `barber-shop-whitelabel`
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Google** sign-in provider:
   - Click on **Google**
   - Toggle **Enable**
   - Enter your **Support email**
   - Click **Save**

### 2. Android Configuration

#### Get SHA-1 Fingerprint

You need to add your app's SHA-1 fingerprint to Firebase for Google Sign-In to work on Android.

**For Debug builds:**
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 fingerprint under `Variant: defaultDebug` → `Config: debug` → `SHA1:`.

**For Release builds:**
If you have a release keystore:
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

#### Add SHA-1 to Firebase

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Click on your Android app (`com.tamebooking.app`)
4. Click **Add fingerprint**
5. Paste your SHA-1 fingerprint
6. Click **Save**

**Important:** After adding SHA-1, download the updated `google-services.json` and replace the one in `android/app/`.

### 3. iOS Configuration

iOS should work automatically once Google Sign-In is enabled in Firebase Console. The `GoogleService-Info.plist` already contains the necessary OAuth client IDs.

**Note:** Make sure your iOS bundle ID (`com.tamebooking.app`) matches the one configured in Firebase Console.

## Apple Sign-In Setup

**⚠️ Important:** Apple Sign-In requires an **Apple Developer Program membership** ($99/year). Without this, Apple Sign-In will not be available and the button will be hidden automatically.

### 1. Apple Developer Account Setup

**Prerequisites:**
- Active Apple Developer Program membership
- App registered in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID (`com.tamebooking.app`)
4. Enable **Sign In with Apple** capability
5. Save the changes

### 2. Configure Sign In with Apple for Web (Required by Firebase)

1. Associate your website with your app as described in [Apple's documentation](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js/configuring_your_webpage_for_sign_in_with_apple)
2. When prompted, register this URL as a Return URL:
   ```
   https://YOUR_FIREBASE_PROJECT_ID.firebaseapp.com/__/auth/handler
   ```
   Replace `YOUR_FIREBASE_PROJECT_ID` with your Firebase project ID (found in Firebase Console → Project Settings)
3. Create a **Sign In with Apple private key** in Apple Developer Portal:
   - Go to **Keys** section
   - Create a new key with **Sign In with Apple** enabled
   - Download the `.p8` key file (you can only download it once!)
   - Note the **Key ID**
4. If you use Firebase Authentication email features, configure Apple's private email relay service:
   - Register `noreply@YOUR_FIREBASE_PROJECT_ID.firebaseapp.com` (or your custom email domain)
   - This allows Apple to relay emails to anonymized Apple email addresses

### 3. Firebase Console Configuration

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Apple** sign-in provider:
   - Click on **Apple**
   - Toggle **Enable**
   - Enter your **Support email**
   - Enter the **Service ID** you created in step 2
   - In **OAuth code flow configuration**:
     - Enter your **Apple Team ID** (found in Apple Developer Portal → Membership)
     - Upload the **private key** (`.p8` file) from step 2
     - Enter the **Key ID** from step 2
   - Click **Save**

### 3. iOS Xcode Configuration

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
2. Select the **Runner** project in the navigator
3. Select the **Runner** target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability**
6. Add **Sign In with Apple**
7. Ensure your **Team** is selected for code signing

### 4. Update Info.plist (if needed)

The `sign_in_with_apple` plugin should handle this automatically, but verify that `ios/Runner/Info.plist` includes:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.tamebooking.app</string>
    </array>
  </dict>
</array>
```

## Testing

### Google Sign-In

1. Run the app: `flutter run`
2. Navigate to the auth screen
3. Tap "Continue with Google"
4. Select a Google account
5. Verify sign-in completes successfully

**Common Issues:**
- **"12500: Sign in with the Google account failed"** → SHA-1 fingerprint not added to Firebase
- **"10: Developer error"** → OAuth client not configured in Firebase

### Apple Sign-In

1. Run the app on a **physical iOS device** (Apple Sign-In doesn't work in simulator)
2. Navigate to the auth screen
3. Tap "Continue with Apple"
4. Complete Apple authentication
5. Verify sign-in completes successfully

**Common Issues:**
- **"Sign In with Apple capability not enabled"** → Enable in Xcode and Apple Developer Portal
- **"Invalid client"** → Apple Sign-In not enabled in Firebase Console
- **"Apple Sign-In is not available"** → You need an Apple Developer Program membership ($99/year)
- **Button doesn't appear** → Apple Sign-In is automatically hidden if not available/configured
- **"Configuration error"** → Verify Service ID, Team ID, private key, and Key ID in Firebase Console

## Troubleshooting

### Android - Google Sign-In Not Working

1. Verify SHA-1 fingerprint is added to Firebase Console
2. Download updated `google-services.json` after adding SHA-1
3. Clean and rebuild:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

### iOS - Apple Sign-In Not Working

1. Verify Sign In with Apple capability is enabled in:
   - Xcode (Signing & Capabilities)
   - Apple Developer Portal (App ID)
   - Firebase Console (Authentication → Sign-in method)

2. Test on a **physical device** (not simulator)

3. Ensure your Apple Developer account has the necessary permissions

## Additional Notes

- **OAuth Client IDs**: After enabling Google/Apple in Firebase, the OAuth client IDs will be automatically added to your `google-services.json` and `GoogleService-Info.plist` files. You may need to re-download these files.

- **Release Builds**: For production, make sure to:
  - Add release SHA-1 fingerprint to Firebase
  - Use proper release signing configuration
  - Test on both debug and release builds

- **Multiple Flavors**: If you have multiple app flavors (different package names/bundle IDs), you'll need to:
  - Create separate Firebase apps for each flavor
  - Configure OAuth clients for each
  - Add SHA-1 fingerprints for each Android flavor
