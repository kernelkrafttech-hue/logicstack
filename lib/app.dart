import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/notifications/application/notifications_providers.dart';

class MaintenanceOSApp extends ConsumerWidget {
  const MaintenanceOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly watch the messaging controller so its auth listener and
    // foreground/tap subscriptions stay alive for the life of the app.
    ref.watch(messagingControllerProvider);

    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
