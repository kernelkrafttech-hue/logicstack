# ContractionTracker

A simple Flutter contraction tracker for expecting mothers. Android is the
primary target; iOS support can be added later.

## Features (MVP)

- Large **Start / Stop Contraction** button on the home screen — green when
  idle, red when a contraction is active.
- Live timer (updates every second) while a contraction is active.
- Scrollable list of all contractions in the current session, each row
  showing contraction number, start time (`h:mm a`), duration in seconds,
  and gap in seconds since the previous one. The first entry shows
  `First contraction` for the gap.
- Summary bar showing the **average duration** and **average gap** of the
  **last 5 contractions**.
- **5-1-1 rule** alert banner: if the last 3 contractions are each ≥ 60 s
  long and the average gap between them is ≤ 300 s, a red banner appears
  with `Time to go to the hospital — call your doctor now.`
- **Reset Session** button in the top-right corner that clears the session
  after a Cancel / Reset confirmation dialog.

## Tech

- Flutter, Android-first.
- All data is kept in-memory only — no database.
- A single `StatefulWidget` (`HomeScreen`) drives the entire UI with a
  `Timer.periodic` for the live tick.
- No external state management libraries.

## Project layout

```
pubspec.yaml          # Flutter project manifest
analysis_options.yaml # Dart analyzer + lint rules
lib/main.dart         # The whole app
```

Platform folders (`android/`, `ios/`) are intentionally not committed in the
initial scaffold. Generate them before the first build:

```sh
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

The `lib/main.dart` file will be preserved by `flutter create`.

## Running

```sh
flutter pub get
flutter run            # run on a connected Android device / emulator
flutter build apk      # build a release APK
```
