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

The `analyzeMaintenanceRequest` callable lives in `functions/`. Configure the
OpenAI key as a Functions secret (it never enters the Flutter app) and deploy:

```bash
cd functions
npm install
firebase functions:secrets:set OPENAI_API_KEY    # paste key when prompted
npm run deploy
```

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

## Roles

`UserRole` defines `landlord`, `tenant`, and `contractor`. The role is captured
on signup, stored on the `users/{uid}` Firestore profile document, and drives
which dashboard the router lands the user on after authentication.

## What's intentionally not here yet

This milestone is the foundation only. Maintenance request flows, property
management, contractor dispatch, and AI features will land in later branches.
