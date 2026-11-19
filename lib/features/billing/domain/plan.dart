/// Subscription plans MaintenanceOS exposes through Stripe.
///
/// `propertyLimit` is the soft cap enforced by the client gate (also
/// enforced server-side by the Stripe checkout function which only accepts
/// known plan ids). `null` means unlimited.
enum Plan {
  freeTrial(
    storageValue: 'free_trial',
    displayName: 'Free Trial',
    monthlyPriceCents: 0,
    propertyLimit: 1,
    aiEnabled: true,
    selectable: false,
  ),
  starter(
    storageValue: 'starter',
    displayName: 'Starter',
    monthlyPriceCents: 1900,
    propertyLimit: 3,
    aiEnabled: false,
    selectable: true,
  ),
  growth(
    storageValue: 'growth',
    displayName: 'Growth',
    monthlyPriceCents: 4900,
    propertyLimit: 20,
    aiEnabled: false,
    selectable: true,
  ),
  pro(
    storageValue: 'pro',
    displayName: 'Pro',
    monthlyPriceCents: 9900,
    propertyLimit: null,
    aiEnabled: true,
    selectable: true,
  );

  const Plan({
    required this.storageValue,
    required this.displayName,
    required this.monthlyPriceCents,
    required this.propertyLimit,
    required this.aiEnabled,
    required this.selectable,
  });

  final String storageValue;
  final String displayName;
  final int monthlyPriceCents;

  /// Maximum number of properties allowed on this plan; `null` = unlimited.
  final int? propertyLimit;

  /// Whether AI analysis (`analyzeMaintenanceRequest`) is included.
  final bool aiEnabled;

  /// Whether this plan can be picked from the subscription screen. The
  /// Free Trial plan is granted automatically, never selected.
  final bool selectable;

  String get priceLabel {
    if (monthlyPriceCents == 0) return 'Free for 14 days';
    final double dollars = monthlyPriceCents / 100;
    return '\$${dollars.toStringAsFixed(0)}/month';
  }

  String get propertyLimitLabel {
    final int? limit = propertyLimit;
    if (limit == null) return 'Unlimited properties';
    return 'Up to $limit ${limit == 1 ? 'property' : 'properties'}';
  }

  /// Bullets shown on the subscription screen under each plan card.
  List<String> get features {
    switch (this) {
      case Plan.freeTrial:
        return <String>[
          '14-day trial · no credit card',
          'Add 1 property to try things out',
          'AI analysis enabled',
        ];
      case Plan.starter:
        return <String>[
          'Up to 3 properties',
          'Maintenance request management',
          'Contractor roster',
        ];
      case Plan.growth:
        return <String>[
          'Up to 20 properties',
          'Comments + activity timeline',
          'Push notifications',
        ];
      case Plan.pro:
        return <String>[
          'Unlimited properties',
          'AI request analysis',
          'Priority support',
        ];
    }
  }

  static Plan fromStorage(String? value) {
    for (final Plan p in Plan.values) {
      if (p.storageValue == value) return p;
    }
    return Plan.freeTrial;
  }
}
