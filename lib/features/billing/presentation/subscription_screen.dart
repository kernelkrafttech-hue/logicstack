import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../application/billing_providers.dart';
import '../data/billing_service.dart';
import '../domain/plan.dart';
import '../domain/subscription.dart';

/// Subscription management screen — current plan summary, plan picker for
/// upgrades / downgrades, and the entry point into Stripe's hosted
/// customer portal for billing detail changes + cancellation.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _busy = false;

  Future<void> _checkout(Plan plan) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final String url =
          await ref.read(billingServiceProvider).startCheckout(plan);
      await _launch(url);
    } on BillingException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPortal() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final String url =
          await ref.read(billingServiceProvider).startCustomerPortal();
      await _launch(url);
    } on BillingException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launch(String url) async {
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showError('Could not open the Stripe page.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Subscription?> async = ref.watch(subscriptionProvider);
    final AppUser? user = ref.watch(appUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (user == null) {
              context.go(AppRoutes.login);
              return;
            }
            context.go(AppRoutes.dashboardFor(user.role));
          },
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => ErrorRetryView(
            message: '$error',
            onRetry: () => ref.invalidate(subscriptionProvider),
          ),
          data: (Subscription? sub) => _Body(
            subscription: sub,
            busy: _busy,
            onCheckout: _checkout,
            onPortal: _openPortal,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.subscription,
    required this.busy,
    required this.onCheckout,
    required this.onPortal,
  });

  final Subscription? subscription;
  final bool busy;
  final void Function(Plan) onCheckout;
  final VoidCallback onPortal;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Plan currentPlan = subscription?.plan ?? Plan.freeTrial;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        _CurrentPlanCard(subscription: subscription, busy: busy, onPortal: onPortal),
        const SizedBox(height: 24),
        Text(
          'Choose a plan',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final Plan plan in Plan.values.where((Plan p) => p.selectable))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanCard(
              plan: plan,
              isCurrent: plan == currentPlan && (subscription?.isEntitled ?? false),
              busy: busy,
              onSelect: () => onCheckout(plan),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Plans renew monthly. Cancel anytime via Manage subscription.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.subscription,
    required this.busy,
    required this.onPortal,
  });

  final Subscription? subscription;
  final bool busy;
  final VoidCallback onPortal;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Subscription? sub = subscription;
    final Plan plan = sub?.plan ?? Plan.freeTrial;

    String renewLine;
    if (sub == null) {
      renewLine = 'Loading subscription state…';
    } else if (sub.isOnTrial) {
      renewLine = 'Trial ends in ${sub.trialDaysRemaining} day${sub.trialDaysRemaining == 1 ? '' : 's'}';
    } else if (sub.cancelAtPeriodEnd && sub.currentPeriodEnd != null) {
      renewLine =
          'Cancels on ${DateFormat.yMMMMd().format(sub.currentPeriodEnd!.toLocal())}';
    } else if (sub.currentPeriodEnd != null) {
      renewLine =
          'Renews on ${DateFormat.yMMMMd().format(sub.currentPeriodEnd!.toLocal())}';
    } else {
      renewLine = sub.status.displayName;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              Text(
                'Current plan',
                style: text.bodySmall?.copyWith(
                  color: AppColors.lightGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.displayName,
            style: text.headlineSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.priceLabel,
            style: text.bodyMedium?.copyWith(color: AppColors.lightGray),
          ),
          const SizedBox(height: 4),
          Text(
            renewLine,
            style: text.bodySmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.lightGray),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed:
                busy || sub?.stripeCustomerId == null ? null : onPortal,
            icon: const Icon(Icons.credit_card_rounded, size: 18),
            label: const Text('Manage subscription'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.busy,
    required this.onSelect,
  });

  final Plan plan;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.green : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      plan.displayName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan.priceLabel,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Current',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final String feature in plan.features) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.greenDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    feature,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: busy || isCurrent ? null : onSelect,
            child: Text(isCurrent ? 'Current plan' : 'Choose ${plan.displayName}'),
          ),
        ],
      ),
    );
  }
}
