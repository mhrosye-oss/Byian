# Firebase setup

## Android client

The Android Firebase client configuration is stored at `android/app/google-services.json` and is processed by the Google Services Gradle plugin. It matches the Android application ID `com.itqan.itqan`. The app initializes Firebase on Android from `lib/main.dart`; platform-specific initialization is guarded in `FirebaseBootstrap`.

The configuration file is client configuration, not a Firebase Admin service-account key. Never place a service-account private key in the mobile app or this repository. Restrict the associated API key in Google Cloud Console to the required APIs and Android application/signing certificates.

## Google sign-in boundary

`GoogleFirebaseAuthService.signInAndGetFirebaseIdToken()` performs Google sign-in and Firebase Authentication, then returns a Firebase ID token. The app's existing API login returns a separate backend bearer token. No Firebase-token exchange endpoint exists in this Flutter repository, so the Google identity is not yet connected to the application's API session and the existing login screen intentionally remains unchanged.

To finish the login flow, the backend must accept and verify a Firebase ID token, map it to an app user, and return the same API bearer-token/session shape used by `JourneyAuthApi`. Enable Google as a Firebase Authentication provider and register the SHA-1 certificate fingerprints used for debug, release, and Play App Signing builds.

## FCM boundary

`FirebaseMessagingService` requests Android notification permission, registers for FCM, exposes the Firebase Installation ID stream, and exposes foreground/opened-message streams. The current backend has no route to register installation IDs or associate them with an authenticated user, so the client deliberately does not upload them. No Firebase Admin credential is included in the app.

To send production pushes, add an authenticated backend registration endpoint and send messages from trusted server infrastructure using Firebase Admin SDK credentials kept outside the mobile app and repository. Foreground messages also need an app-level subscriber to display or route them.

## iOS not configured yet

The supplied configuration is Android-only. Before enabling Firebase Auth or FCM on iOS, add the Firebase-generated `GoogleService-Info.plist` for bundle ID `com.itqan.itqan` to the Runner target. FCM on Apple platforms also requires the Push Notifications and Background Modes capabilities and an APNs authentication key uploaded to Firebase. The current bootstrap intentionally leaves Firebase disabled on iOS until these files and capabilities are present.
