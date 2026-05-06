import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/dashboard/presentation/contractor_dashboard.dart';
import '../../features/dashboard/presentation/landlord_dashboard.dart';
import '../../features/dashboard/presentation/tenant_dashboard.dart';
import '../../features/properties/presentation/add_property_screen.dart';
import '../../features/properties/presentation/properties_list_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/requests/presentation/landlord_request_detail_screen.dart';
import '../../features/requests/presentation/maintenance_requests_screen.dart';
import '../../features/requests/presentation/request_detail_screen.dart';
import '../../features/requests/presentation/submit_request_screen.dart';
import '../../features/requests/presentation/widgets/request_filter_bar.dart';
import '../../features/splash/splash_screen.dart';

/// Routes the app exposes. Centralised so we can refer to them by name
/// instead of sprinkling string literals through the codebase.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String landlord = '/landlord';
  static const String tenant = '/tenant';
  static const String contractor = '/contractor';

  // Landlord -> Properties
  static const String properties = '/landlord/properties';
  static const String propertyNew = '/landlord/properties/new';
  static String propertyDetailFor(String id) => '/landlord/properties/$id';

  // Landlord -> Maintenance requests
  static const String landlordRequests = '/landlord/requests';
  static String landlordRequestsWithFilter(RequestFilter filter) =>
      '/landlord/requests?filter=${filter.name}';
  static String landlordRequestDetailFor(String id) =>
      '/landlord/requests/$id';

  // Tenant -> Maintenance requests
  static const String requestNew = '/tenant/requests/new';
  static String requestDetailFor(String id) => '/tenant/requests/$id';

  /// Path prefixes that scope a route to a single role. Used by the redirect
  /// to keep tenants/contractors out of landlord-only screens.
  static const Map<UserRole, String> rolePrefixes = <UserRole, String>{
    UserRole.landlord: landlord,
    UserRole.tenant: tenant,
    UserRole.contractor: contractor,
  };

  static String dashboardFor(UserRole role) {
    switch (role) {
      case UserRole.landlord:
        return landlord;
      case UserRole.tenant:
        return tenant;
      case UserRole.contractor:
        return contractor;
    }
  }
}

/// Bridges a Riverpod stream into a [Listenable] so GoRouter can `refresh`
/// its redirect logic when auth state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _sub = ref.listen<AsyncValue<AppUser?>>(
      appUserProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
    _authSub = ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<AsyncValue<AppUser?>> _sub;
  late final ProviderSubscription<AsyncValue<User?>> _authSub;

  @override
  void dispose() {
    _sub.close();
    _authSub.close();
    super.dispose();
  }
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(
  (ProviderRef<GoRouter> ref) {
    final _RouterRefreshNotifier refresh = _RouterRefreshNotifier(ref);
    ref.onDispose(refresh.dispose);

    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: refresh,
      redirect: (BuildContext context, GoRouterState state) {
        final AsyncValue<User?> auth = ref.read(authStateProvider);
        final AsyncValue<AppUser?> profile = ref.read(appUserProvider);

        // Still resolving the initial auth or profile fetch.
        if (auth.isLoading || (auth.valueOrNull != null && profile.isLoading)) {
          return AppRoutes.splash;
        }

        final bool signedIn = auth.valueOrNull != null;
        final String location = state.matchedLocation;
        final bool onAuthScreen =
            location == AppRoutes.login || location == AppRoutes.signup;
        final bool onSplash = location == AppRoutes.splash;

        if (!signedIn) {
          return onAuthScreen ? null : AppRoutes.login;
        }

        // Signed in but the Firestore profile hasn't materialised yet.
        final AppUser? appUser = profile.valueOrNull;
        if (appUser == null) {
          return AppRoutes.splash;
        }

        final String target = AppRoutes.dashboardFor(appUser.role);
        if (onAuthScreen || onSplash) return target;

        // Prevent visiting any route scoped to a different role (e.g. a
        // tenant trying to load /landlord/properties/abc).
        for (final MapEntry<UserRole, String> entry
            in AppRoutes.rolePrefixes.entries) {
          if (entry.key == appUser.role) continue;
          if (location == entry.value ||
              location.startsWith('${entry.value}/')) {
            return target;
          }
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.splash,
          builder: (BuildContext context, GoRouterState state) =>
              const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (BuildContext context, GoRouterState state) =>
              const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.landlord,
          builder: (BuildContext context, GoRouterState state) {
            final AppUser? user = ref.read(appUserProvider).valueOrNull;
            if (user == null) return const SplashScreen();
            return LandlordDashboard(user: user);
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'properties',
              builder: (BuildContext context, GoRouterState state) =>
                  const PropertiesListScreen(),
              routes: <RouteBase>[
                // Order matters: `new` is matched before `:id`.
                GoRoute(
                  path: 'new',
                  builder: (BuildContext context, GoRouterState state) =>
                      const AddPropertyScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (BuildContext context, GoRouterState state) {
                    final String? id = state.pathParameters['id'];
                    if (id == null || id.isEmpty) {
                      return const SplashScreen();
                    }
                    return PropertyDetailScreen(propertyId: id);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'requests',
              builder: (BuildContext context, GoRouterState state) {
                final String? raw = state.uri.queryParameters['filter'];
                RequestFilter? initial;
                if (raw != null) {
                  for (final RequestFilter f in RequestFilter.values) {
                    if (f.name == raw) {
                      initial = f;
                      break;
                    }
                  }
                }
                return MaintenanceRequestsScreen(initialFilter: initial);
              },
              routes: <RouteBase>[
                GoRoute(
                  path: ':id',
                  builder: (BuildContext context, GoRouterState state) {
                    final String? id = state.pathParameters['id'];
                    if (id == null || id.isEmpty) {
                      return const SplashScreen();
                    }
                    return LandlordRequestDetailScreen(requestId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.tenant,
          builder: (BuildContext context, GoRouterState state) {
            final AppUser? user = ref.read(appUserProvider).valueOrNull;
            if (user == null) return const SplashScreen();
            return TenantDashboard(user: user);
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'requests/new',
              builder: (BuildContext context, GoRouterState state) =>
                  const SubmitRequestScreen(),
            ),
            GoRoute(
              path: 'requests/:id',
              builder: (BuildContext context, GoRouterState state) {
                final String? id = state.pathParameters['id'];
                if (id == null || id.isEmpty) {
                  return const SplashScreen();
                }
                return RequestDetailScreen(requestId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.contractor,
          builder: (BuildContext context, GoRouterState state) {
            final AppUser? user = ref.read(appUserProvider).valueOrNull;
            if (user == null) return const SplashScreen();
            return ContractorDashboard(user: user);
          },
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Page not found:\n${state.uri}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  },
);
