import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

/// FCM background handler. Must be a top-level entry point so the Flutter
/// engine can find it when the app is terminated. We initialize Firebase
/// here because the engine spawns a fresh isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  // Wrap startup in a guarded zone so any uncaught async error during
  // bootstrap is captured by Crashlytics rather than crashing silently.
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Persistent offline cache for Firestore. Mobile platforms enable
      // this by default; spelling it out keeps web behaviour explicit.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Crashlytics: only collect on release builds — debug crashes are
      // noise and would flood the console with already-visible errors.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Replace the default red screen-of-death in release builds with a
      // friendlier full-screen error boundary.
      if (!kDebugMode) {
        ErrorWidget.builder = (FlutterErrorDetails details) =>
            const _AppErrorWidget();
      }

      // Must be set before runApp so the OS hooks the handler before any
      // background message can arrive.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      runApp(const ProviderScope(child: MaintenanceOSApp()));
    },
    (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class _AppErrorWidget extends StatelessWidget {
  const _AppErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B2545),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFF1FB57A),
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The app hit an unexpected error. Please restart — if the '
                'problem keeps happening, contact support from the Settings '
                'screen.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
