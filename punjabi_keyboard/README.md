# Punjabi Keyboard (Android, Flutter + native IME)

A Punjabi (Gurmukhi) keyboard for Android. Includes:

- System-wide Gurmukhi **Input Method Editor (IME)** — works in any app like WhatsApp, Gmail, etc.
- Emoji & Gurmukhi sticker panel inside the keyboard.
- Companion app with an **"Talk → Punjabi text"** speech-to-text feature.
- Premium tier to **remove ads** (Google Mobile Ads is wired in with test IDs).
- Settings: vibration, sound, auto-cap, number row.

iOS is planned; Apple's App Store requires a separate Swift project and a
different IME entitlement model, so this initial repo targets Android first.

## Architecture

```
punjabi_keyboard/
├── lib/                         ← Flutter (companion app)
│   ├── screens/                   home, speech, emoji, premium, settings
│   ├── services/                  premium, ads, speech, method-channel
│   └── data/punjabi_emojis.dart
└── android/
    └── app/src/main/
        ├── AndroidManifest.xml              ← declares IME service
        ├── res/xml/method.xml               ← IME subtypes (pa_IN, en_US)
        └── kotlin/.../ime/
            ├── PunjabiInputMethodService.kt ← extends InputMethodService
            ├── KeyboardView.kt              ← soft keyboard view
            ├── EmojiView.kt                 ← emoji/sticker panel
            ├── GurmukhiLayout.kt            ← key layouts + long-press alts
            └── EmojiPalette.kt
```

A native `InputMethodService` is required because the Android system only
lets native services act as a keyboard — Flutter alone can't host an IME.
The Flutter app ships as the **companion/settings app**; the keyboard is
a native Kotlin service in the same APK.

## Tooling

- **Flutter 3.19+** (Dart SDK 3.3+)
- **Android Studio** or **VS Code + Flutter extension** is the best dev
  experience. (Visual Studio on Windows does not have first-class Flutter
  support — use Visual Studio *Code* instead.)
- Android SDK: min 23, target/compile 34.

## Build

```bash
cd punjabi_keyboard
flutter pub get
flutter run -d android
```

First-run permissions inside the app:

1. Tap **"Open settings"** → enable **Punjabi Keyboard** in Languages & input.
2. Tap **"Choose keyboard"** → pick **Punjabi Keyboard** in the IME switcher.
3. Grant microphone permission when prompted by the speech screen.

## Feature notes

### Keyboard
- Gurmukhi letters grouped phonetically; long-press alternates for
  aspirated/nuqta forms.
- `🌐` switches to the system IME picker; `?123` swaps to the symbol layer
  (includes Gurmukhi numerals ੦–੯).
- `😊` opens the in-keyboard emoji/sticker panel.

### Speech → Punjabi
`SpeechService` uses the `speech_to_text` plugin with locale `pa_IN`.
If the device doesn't have a Punjabi recognizer installed, Android falls
back to the best available locale — the user should install the Punjabi
pack via *Settings → System → Languages → Google → Offline speech*.

### Ads & Premium
- `BannerAdWidget` renders the Google Mobile Ads test banner on the home
  screen. Replace `ca-app-pub-3940256099942544/6300978111` and the
  `APPLICATION_ID` in `AndroidManifest.xml` with real IDs before release.
- `PremiumService` persists the premium flag in shared preferences. The
  in-app-purchase flow is scaffolded — product id
  `punjabi_keyboard_premium` needs to be created in Play Console and
  wired into `PremiumScreen._purchase()`.

## TODO before shipping

- Replace AdMob test IDs with real IDs.
- Replace the debug toggle in `PremiumScreen` with a real
  `in_app_purchase` flow and receipt verification.
- Add icons in `android/app/src/main/res/mipmap-*`.
- iOS project (InputMethod extension in Swift).
- Word suggestions / autocorrect dictionary (Gurmukhi).
