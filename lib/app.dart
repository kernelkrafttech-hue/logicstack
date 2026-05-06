import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/application/notifications_providers.dart';

class MaintenanceOSApp extends ConsumerWidget {
  const MaintenanceOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly watch the messaging controller so its auth listener and
    // foreground/tap subscriptions stay alive for the life of the app.
    ref.watch(messagingControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
