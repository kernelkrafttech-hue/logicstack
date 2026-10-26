import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/billing_service.dart';
import '../data/subscription_repository.dart';
import '../domain/plan.dart';
import '../domain/subscription.dart';

final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>(
  (ProviderRef<SubscriptionRepository> ref) => SubscriptionRepository(),
);

final Provider<BillingService> billingServiceProvider = Provider<BillingService>(
  (ProviderRef<BillingService> ref) => BillingService(),
);

/// Live current subscription for the signed-in user. Null while loading or
/// when nobody is signed in.
final StreamProvider<Subscription?> subscriptionProvider =
    StreamProvider<Subscription?>(
  (StreamProviderRef<Subscription?> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream<Subscription?>.value(null);
    return ref.watch(subscriptionRepositoryProvider).watchCurrent(user.uid);
  },
);

/// Outcome of a feature gate check. The UI can either dismiss (allowed),
/// or show the upgrade banner with [reason].
class GateResult {
  const GateResult.allowed()
      : allowed = true,
        reason = '',
        suggestedPlan = null;

  const GateResult.blocked(this.reason, {this.suggestedPlan})
      : allowed = false;

  final bool allowed;
  final String reason;
  final Plan? suggestedPlan;
}

/// Property creation gate — checks the active plan's `propertyLimit`
/// against the current property count. Falls open while data loads so the
/// user isn't blocked on a slow Firestore round-trip.
GateResult checkCanAddProperty({
  required Subscription? subscription,
  required int currentPropertyCount,
}) {
  final Subscription? sub = subscription;
  if (sub == null) return const GateResult.allowed();
  if (!sub.isEntitled) {
    return GateResult.blocked(
      'Your subscription is ${sub.status.displayName.toLowerCase()}. Reactivate to add more properties.',
      suggestedPlan: Plan.starter,
    );
  }
  final int? limit = sub.plan.propertyLimit;
  if (limit == null) return const GateResult.allowed();
  if (currentPropertyCount < limit) return const GateResult.allowed();
  return GateResult.blocked(
    'You\'ve hit the ${sub.plan.displayName} plan\'s limit of $limit '
    '${limit == 1 ? 'property' : 'properties'}. Upgrade to add more.',
    suggestedPlan: _nextPaidPlan(sub.plan),
  );
}

/// AI feature gate — Phase 5's analyzeMaintenanceRequest only runs on
/// plans where [Plan.aiEnabled] is true.
GateResult checkCanUseAi(Subscription? subscription) {
  final Subscription? sub = subscription;
  if (sub == null) return const GateResult.allowed();
  if (!sub.isEntitled) {
    return GateResult.blocked(
      'Reactivate your subscription to use AI request analysis.',
      suggestedPlan: Plan.pro,
    );
  }
  if (sub.plan.aiEnabled) return const GateResult.allowed();
  return GateResult.blocked(
    'AI request analysis is included on the Pro plan.',
    suggestedPlan: Plan.pro,
  );
}

Plan _nextPaidPlan(Plan current) {
  switch (current) {
    case Plan.freeTrial:
    case Plan.starter:
      return Plan.growth;
    case Plan.growth:
      return Plan.pro;
    case Plan.pro:
      return Plan.pro;
  }
}
