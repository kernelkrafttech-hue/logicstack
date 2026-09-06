import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../billing/application/billing_providers.dart';
import '../../../billing/domain/subscription.dart';
import '../../../billing/presentation/widgets/upgrade_banner.dart';
import '../../application/request_providers.dart';
import '../../data/request_repository.dart';
import '../../domain/maintenance_request.dart';
import 'urgency_badge.dart';

/// AI insights block on the landlord request detail screen.
///
/// Renders the four AI fields (or empty-state copy when analysis hasn't
/// run yet) and provides a "Regenerate" button that calls the
/// `analyzeMaintenanceRequest` Cloud Function.
class AiInsightsSection extends ConsumerWidget {
  const AiInsightsSection({required this.request, super.key});

  final MaintenanceRequest request;

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final bool ok = await ref
        .read(regenerateAiControllerProvider.notifier)
        .regenerate(request);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI analysis updated.')),
      );
      return;
    }
    final AsyncValue<void> state = ref
        .read(regenerateAiControllerProvider.notifier)
        .stateFor(request.id);
    final Object? error = state.error;
    final String message = error is RequestException
        ? error.message
        : 'Could not regenerate analysis.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    // Watch the per-request AI controller state so the spinner appears even
    // if another request's regenerate is in flight.
    final AsyncValue<void> regenState = ref.watch(
      regenerateAiControllerProvider.select(
        (Map<String, AsyncValue<void>> map) =>
            map[request.id] ?? const AsyncValue<void>.data(null),
      ),
    );
    final bool loading = regenState.isLoading;
    final bool hasError = regenState.hasError;
    final bool hasAnalysis = request.hasAiAnalysis;
    final Subscription? subscription =
        ref.watch(subscriptionProvider).valueOrNull;
    final GateResult gate = checkCanUseAi(subscription);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.greenDark,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'AI insights',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: loading || !gate.allowed
                  ? null
                  : () => _regenerate(context, ref),
              icon: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                hasAnalysis ? 'Regenerate' : 'Generate',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!gate.allowed) ...<Widget>[
          UpgradeBanner(
            message: gate.reason,
            suggestedPlan: gate.suggestedPlan,
          ),
          const SizedBox(height: 10),
        ],
        if (loading && !hasAnalysis)
          const _LoadingBlock()
        else if (!hasAnalysis)
          _EmptyBlock(hasError: hasError)
        else ...<Widget>[
          _InsightCard(
            label: 'AI summary',
            icon: Icons.subject_rounded,
            child: Text(
              request.aiSummary?.isNotEmpty == true
                  ? request.aiSummary!
                  : 'No summary returned.',
              style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
            ),
          ),
          const SizedBox(height: 10),
          _InsightCard(
            label: 'Likely trade',
            icon: Icons.engineering_rounded,
            child: Text(
              request.likelyTrade?.isNotEmpty == true
                  ? request.likelyTrade!
                  : '—',
              style: text.bodyMedium?.copyWith(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _InsightCard(
            label: 'Suggested urgency',
            icon: Icons.priority_high_rounded,
            child: _UrgencySuggestion(request: request),
          ),
          const SizedBox(height: 10),
          _InsightCard(
            label: 'Contractor message',
            icon: Icons.send_rounded,
            child: Text(
              request.contractorMessage?.isNotEmpty == true
                  ? request.contractorMessage!
                  : 'No message generated.',
              style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
            ),
          ),
          if (request.aiAnalyzedAt != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Analyzed ${DateFormat.yMMMd().add_jm().format(request.aiAnalyzedAt!.toLocal())}',
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ],
        if (loading && hasAnalysis) ...<Widget>[
          const SizedBox(height: 10),
          const _LoadingBlock(message: 'Re-running analysis…'),
        ],
      ],
    );
  }
}

class _UrgencySuggestion extends StatelessWidget {
  const _UrgencySuggestion({required this.request});
  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final RequestUrgency? mapped = request.aiUrgencyEnum;
    if (mapped == null) {
      return Text(
        request.urgencySuggestion?.isNotEmpty == true
            ? request.urgencySuggestion!
            : '—',
        style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
      );
    }
    final bool differs = mapped != request.urgency;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        UrgencyBadge(urgency: mapped),
        if (differs) ...<Widget>[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'AI thinks this should be ${mapped.displayName.toLowerCase()} '
              '(tenant chose ${request.urgency.displayName.toLowerCase()}).',
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 6),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({this.message = 'Analyzing with AI…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.hasError});
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            hasError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
            color: hasError ? AppColors.error : AppColors.mutedText,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasError
                  ? 'Analysis failed. Tap "Generate" to retry.'
                  : 'Analysis hasn\'t run yet. Tap "Generate" to summarise this request.',
              style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}
