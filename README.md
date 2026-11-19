# MaintenanceOS

AI-powered maintenance coordination platform for small landlords, tenants, and
contractors. This repository hosts the Flutter MVP foundation.

## Stack

- Flutter (Material 3, Inter via `google_fonts`)
- Firebase Auth, Cloud Firestore, Firebase Storage, Cloud Functions
- Riverpod for state management
- GoRouter for auth-aware navigation

## Project layout

```
lib/
├── main.dart                       # Entry point, Firebase init, ProviderScope
├── app.dart                        # MaterialApp.router shell
├── firebase_options.dart           # Replace via `flutterfire configure`
├── core/
│   ├── constants/                  # App-wide constants
│   ├── router/                     # GoRouter + auth-aware redirects
│   ├── theme/                      # Brand colors + ThemeData
│   └── utils/                      # Validators, helpers
├── features/
│   ├── auth/
│   │   ├── application/            # Riverpod providers + controllers
│   │   ├── data/                   # AuthRepository (Firebase Auth + Firestore)
│   │   ├── domain/                 # AppUser, UserRole
│   │   └── presentation/           # Login, signup, role picker
│   ├── dashboard/presentation/     # Landlord, tenant, contractor dashboards
│   └── splash/                     # Splash while auth resolves
└── shared/widgets/                 # Reusable UI primitives
```

## Setup

```bash
flutter pub get

# Generate firebase_options.dart for your project (overwrites the placeholder):
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project>

flutter run
```

Once the project is connected, deploy security rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### Cloud Functions

`functions/` holds three feature areas: `analyze.ts` (OpenAI-backed AI
analysis), `notifications.ts` (FCM fan-out triggers), and `billing.ts`
(Stripe subscriptions). Every secret stays on the server.

```bash
cd functions
npm install

# AI
firebase functions:secrets:set OPENAI_API_KEY

# Stripe
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set STRIPE_PRICE_STARTER   # price_xxx
firebase functions:secrets:set STRIPE_PRICE_GROWTH    # price_xxx
firebase functions:secrets:set STRIPE_PRICE_PRO       # price_xxx
firebase functions:secrets:set STRIPE_PORTAL_RETURN_URL  # https://your-app/return

npm run deploy
```

After deploying, copy the deployed URL of `stripeWebhook` and register it
in the Stripe dashboard for the `customer.subscription.created`,
`customer.subscription.updated`, and `customer.subscription.deleted`
events. The signing secret it shows you is what `STRIPE_WEBHOOK_SECRET`
should be set to.

Plans are wired by Stripe Price IDs — create three recurring USD prices in
Stripe ($19, $49, $99/month) and feed their `price_xxx` ids to the secrets
above. The 14-day free trial is seeded by `seedFreeTrialOnUserCreated` on
sign-up, so no Stripe interaction is needed before paid plans kick in.

To run locally against the emulator:

```bash
cd functions
npm run serve
```

### Platform setup for `image_picker`

The maintenance request flow uses the system photo picker. After running
`flutter create .` to materialise platform folders, add:

- **iOS** — `ios/Runner/Info.plist`:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>MaintenanceOS needs access to add photos to your maintenance requests.</string>
  <key>NSCameraUsageDescription</key>
  <string>MaintenanceOS needs camera access if you take photos of an issue.</string>
  ```
- **Android** — no manifest changes are required for `image_picker` 1.x on
  modern Android (it uses the Photo Picker / scoped storage).

### Crashlytics, Analytics, and platform extras

`flutterfire configure` already enables Analytics + Crashlytics for the
Flutter app, but two platform tweaks land outside Dart code:

- **Android** — Crashlytics requires the Gradle plugin. After running
  `flutter create .`, add to `android/app/build.gradle`:

  ```gradle
  apply plugin: 'com.google.gms.google-services'
  apply plugin: 'com.google.firebase.crashlytics'
  ```
  and to `android/build.gradle`:

  ```gradle
  classpath 'com.google.gms:google-services:4.4.2'
  classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2'
  ```

- **iOS** — open `ios/Runner.xcworkspace` and run a release build at least
  once so Crashlytics symbols upload via the `dSYMs` build phase that
  `flutterfire configure` injects.

### App icon and splash screen

Use `flutter_native_splash` and `flutter_launcher_icons` after running
`flutter create .`. Drop your master icon at
`assets/icon/maintenanceos-icon.png` and add this to `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  image_path: assets/icon/maintenanceos-icon.png
  android: true
  ios: true

flutter_native_splash:
  color: "#0B2545"
  image: assets/icon/maintenanceos-icon.png
  android_12:
    color: "#0B2545"
    image: assets/icon/maintenanceos-icon.png
```

then run `dart run flutter_native_splash:create` and
`dart run flutter_launcher_icons`.

### Platform setup for FCM (`firebase_messaging`)

- **iOS**
  - Enable the **Push Notifications** capability in Xcode for the Runner
    target.
  - Enable **Background Modes → Remote notifications**.
  - Upload an APNs auth key in the Firebase console (Project settings →
    Cloud Messaging).
- **Android**
  - `flutterfire configure` writes `android/app/google-services.json` and
    the gradle plugin entries.
  - Android 13+ shows the runtime POST_NOTIFICATIONS prompt automatically
    on first `requestPermission()` call.

## Roles

`UserRole` defines `landlord`, `tenant`, and `contractor`. The role is captured
on signup, stored on the `users/{uid}` Firestore profile document, and drives
which dashboard the router lands the user on after authentication.

## What's intentionally not here yet

This milestone is the foundation only. Maintenance request flows, property
management, contractor dispatch, and AI features will land in later branches.
