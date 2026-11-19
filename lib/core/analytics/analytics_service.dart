import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around [FirebaseAnalytics] that exposes the events we care
/// about for the launch dashboard. The handful of named methods keeps the
/// call sites typed and self-documenting — the alternative (raw
/// `logEvent` calls scattered across controllers) makes it easy to drift
/// off the schema.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// [FirebaseAnalyticsObserver] hooked into MaterialApp.router so each
  /// GoRoute change is recorded as a screen view automatically.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);

  Future<void> setUserRole(String role) =>
      _analytics.setUserProperty(name: 'app_role', value: role);

  Future<void> logSignUp({required String role}) {
    return _analytics.logSignUp(signUpMethod: 'email').then(
          (_) => _analytics.logEvent(
            name: 'maintenanceos_signup',
            parameters: <String, Object?>{'role': role},
          ),
        );
  }

  Future<void> logRequestCreated({
    required String requestId,
    required String category,
    required String urgency,
  }) {
    return _analytics.logEvent(
      name: 'request_created',
      parameters: <String, Object?>{
        'request_id': requestId,
        'category': category,
        'urgency': urgency,
      },
    );
  }

  Future<void> logContractorAssigned({
    required String requestId,
    required String trade,
  }) {
    return _analytics.logEvent(
      name: 'contractor_assigned',
      parameters: <String, Object?>{
        'request_id': requestId,
        'trade': trade,
      },
    );
  }

  Future<void> logSubscriptionCheckoutStarted({required String planId}) {
    return _analytics.logEvent(
      name: 'subscription_checkout_started',
      parameters: <String, Object?>{'plan_id': planId},
    );
  }

  Future<void> logSubscriptionUpgraded({
    required String planId,
    required String previousPlanId,
  }) {
    return _analytics.logEvent(
      name: 'subscription_upgraded',
      parameters: <String, Object?>{
        'plan_id': planId,
        'previous_plan_id': previousPlanId,
      },
    );
  }
}

final Provider<AnalyticsService> analyticsServiceProvider =
    Provider<AnalyticsService>(
  (ProviderRef<AnalyticsService> ref) => AnalyticsService(),
);
