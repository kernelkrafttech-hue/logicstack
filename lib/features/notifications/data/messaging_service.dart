import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';

/// Wraps the FirebaseMessaging plugin with the bits of glue specific to
/// MaintenanceOS — token registration into the per-user subcollection,
/// permission requests, and exposing message streams.
class MessagingService {
  MessagingService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  /// Foreground messages: the system OS doesn't surface a banner here, so
  /// the app shows a snackbar instead. Background and terminated messages
  /// are still rendered by the OS.
  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  /// User taps a system notification while the app is backgrounded.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Returns the message that launched the app from a terminated state, if
  /// any. Should be checked once on startup and consumed.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  /// Registers (or refreshes) the FCM token for [uid] under
  /// `users/{uid}/fcmTokens/{token}`. Stored idempotently — using the
  /// token itself as the doc id deduplicates across re-registrations.
  Future<String?> registerTokenFor(String uid) async {
    try {
      final String? token = await _messaging.getToken();
      if (token == null || token.isEmpty) return null;
      await _writeToken(uid: uid, token: token);
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessagingService: failed to get FCM token: $e');
      }
      return null;
    }
  }

  Future<void> _writeToken({required String uid, required String token}) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.fcmTokensSubcollection)
        .doc(token)
        .set(<String, Object?>{
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> deleteTokenFor(String uid) async {
    try {
      final String? token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.fcmTokensSubcollection)
          .doc(token)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MessagingService: failed to delete token: $e');
      }
    }
  }
}
