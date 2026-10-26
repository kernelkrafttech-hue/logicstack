import 'package:cloud_firestore/cloud_firestore.dart';

import 'plan.dart';

/// Stripe subscription state mirrored into Firestore by the Stripe webhook
/// Cloud Function.
///
/// Backed by `users/{uid}/subscription/current`. The webhook is the only
/// writer; clients read this doc to decide what features to expose.
class Subscription {
  const Subscription({
    required this.userId,
    required this.plan,
    required this.status,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.currentPeriodEnd,
    this.trialEnd,
    this.cancelAtPeriodEnd = false,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final Plan plan;
  final SubscriptionStatus status;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True when the user can use any paid features. Trials count as active.
  bool get isEntitled =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;

  /// True when the trial is still running (used to show countdown UI).
  bool get isOnTrial =>
      status == SubscriptionStatus.trialing && trialEnd != null;

  /// Days remaining in the trial — clamped to 0 when expired.
  int get trialDaysRemaining {
    final DateTime? end = trialEnd;
    if (end == null) return 0;
    final int days = end.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  static Subscription fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return Subscription(
      userId: (data['userId'] as String?) ?? '',
      plan: Plan.fromStorage(data['planId'] as String?),
      status: SubscriptionStatus.fromStorage(data['status'] as String?),
      stripeCustomerId: data['stripeCustomerId'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      currentPeriodEnd:
          (data['currentPeriodEnd'] as Timestamp?)?.toDate(),
      trialEnd: (data['trialEnd'] as Timestamp?)?.toDate(),
      cancelAtPeriodEnd: (data['cancelAtPeriodEnd'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

enum SubscriptionStatus {
  trialing('trialing', 'Trialing'),
  active('active', 'Active'),
  pastDue('past_due', 'Past due'),
  canceled('canceled', 'Canceled'),
  incomplete('incomplete', 'Incomplete'),
  unpaid('unpaid', 'Unpaid');

  const SubscriptionStatus(this.storageValue, this.displayName);

  final String storageValue;
  final String displayName;

  static SubscriptionStatus fromStorage(String? value) {
    for (final SubscriptionStatus s in SubscriptionStatus.values) {
      if (s.storageValue == value) return s;
    }
    return SubscriptionStatus.incomplete;
  }
}
