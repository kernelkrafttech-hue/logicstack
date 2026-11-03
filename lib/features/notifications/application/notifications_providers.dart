import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../data/messaging_service.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

final Provider<NotificationsRepository> notificationsRepositoryProvider =
    Provider<NotificationsRepository>(
  (ProviderRef<NotificationsRepository> ref) => NotificationsRepository(),
);

final Provider<MessagingService> messagingServiceProvider =
    Provider<MessagingService>(
  (ProviderRef<MessagingService> ref) => MessagingService(),
);

/// Live list of the current user's most recent notifications. Empty when
/// signed out.
final StreamProvider<List<AppNotification>> myNotificationsProvider =
    StreamProvider<List<AppNotification>>(
  (StreamProviderRef<List<AppNotification>> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Stream<List<AppNotification>>.value(<AppNotification>[]);
    }
    return ref
        .watch(notificationsRepositoryProvider)
        .watchNotificationsForUser(user.uid);
  },
);

/// Reactive unread count derived from [myNotificationsProvider]. Used by the
/// app bar bell badge.
final Provider<int> unreadNotificationCountProvider = Provider<int>(
  (ProviderRef<int> ref) {
    final AsyncValue<List<AppNotification>> async =
        ref.watch(myNotificationsProvider);
    final List<AppNotification> list = async.valueOrNull ?? const <AppNotification>[];
    return list.where((AppNotification n) => !n.read).length;
  },
);

/// Global key the [MessagingController] uses to surface foreground push
/// notifications as snackbars without needing a [BuildContext].
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Glue between Firebase Auth and the FCM token store. Eagerly listened to
/// from [MaintenanceOSApp] so it stays alive for the life of the process.
class MessagingController {
  MessagingController(this._service, this._ref);

  final MessagingService _service;
  final Ref _ref;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _registeredUid;
  bool _bootstrapped = false;

  /// One-time setup: request permission, ask for the launch message,
  /// subscribe to message + token streams. Auth-state changes are wired in
  /// the Provider body using [ref.listen].
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    await _service.requestPermission();

    _foregroundSub = _service.onForegroundMessage.listen(_handleForeground);
    _openedSub = _service.onMessageOpenedApp.listen(_handleOpened);
    _tokenRefreshSub = _service.onTokenRefresh.listen((String _) {
      final String? uid = _registeredUid;
      if (uid != null) {
        _service.registerTokenFor(uid);
      }
    });

    final RemoteMessage? launch = await _service.getInitialMessage();
    if (launch != null) _handleOpened(launch);
  }

  Future<void> onSignedIn(String uid) async {
    _registeredUid = uid;
    await _service.registerTokenFor(uid);
  }

  Future<void> onSignedOut(String uid) async {
    _registeredUid = null;
    await _service.deleteTokenFor(uid);
  }

  void _handleForeground(RemoteMessage message) {
    final String title = message.notification?.title ?? 'New notification';
    final String body = message.notification?.body ?? '';
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateForMessage(message),
        ),
      ),
    );
  }

  void _handleOpened(RemoteMessage message) {
    _navigateForMessage(message);
  }

  void _navigateForMessage(RemoteMessage message) {
    final String? requestId = message.data['requestId'] as String?;
    if (requestId == null || requestId.isEmpty) {
      // No deep-link payload — go to the notifications list.
      _go(AppRoutes.notifications);
      return;
    }
    final AppUser? user = _ref.read(appUserProvider).valueOrNull;
    if (user == null) {
      _go(AppRoutes.notifications);
      return;
    }
    _go(AppRoutes.requestDetailForRole(user.role, requestId));
  }

  void _go(String location) {
    final BuildContext? ctx = rootScaffoldMessengerKey.currentContext;
    if (ctx == null) return;
    GoRouter.of(ctx).go(location);
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
  }
}

/// Eagerly-watched provider that wires auth state to FCM token registration
/// and starts foreground / tap handling. Watched once from `MaintenanceOSApp`
/// so its `ref.listen` callbacks survive for the life of the app.
final Provider<MessagingController> messagingControllerProvider =
    Provider<MessagingController>(
  (ProviderRef<MessagingController> ref) {
    final MessagingController controller = MessagingController(
      ref.watch(messagingServiceProvider),
      ref,
    );
    // ignore: discarded_futures
    controller.bootstrap();

    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (AsyncValue<User?>? prev, AsyncValue<User?> next) {
        final User? prevUser = prev?.valueOrNull;
        final User? nextUser = next.valueOrNull;
        if (nextUser != null && nextUser.uid != prevUser?.uid) {
          // ignore: discarded_futures
          controller.onSignedIn(nextUser.uid);
        } else if (nextUser == null && prevUser != null) {
          // ignore: discarded_futures
          controller.onSignedOut(prevUser.uid);
        }
      },
      fireImmediately: true,
    );

    ref.onDispose(() {
      // ignore: discarded_futures
      controller.dispose();
    });

    return controller;
  },
);
