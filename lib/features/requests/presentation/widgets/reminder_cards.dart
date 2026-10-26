import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/comments_providers.dart';
import '../../data/comments_repository.dart';
import '../../domain/maintenance_request.dart';

/// Landlord-side nudge: shown when a request has been waiting on the
/// contractor for more than 24h. Returns `null` when not applicable so the
/// caller can drop it from the layout entirely.
class ContractorWaitingReminder extends StatelessWidget {
  const ContractorWaitingReminder({required this.request, super.key});

  final MaintenanceRequest request;

  static const Duration _threshold = Duration(hours: 24);

  static bool isApplicable(MaintenanceRequest r) {
    if (r.status != RequestStatus.sentToContractor) return false;
    final DateTime? since = r.assignedAt ?? r.updatedAt;
    if (since == null) return false;
    return DateTime.now().difference(since) >= _threshold;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Duration since = DateTime.now().difference(
      request.assignedAt ?? request.updatedAt ?? DateTime.now(),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Contractor has not responded yet',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Waiting ${_formatHours(since)} since assignment. Consider following up with the contractor or reassigning.',
                  style: text.bodySmall?.copyWith(color: AppColors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(Duration d) {
    final int hours = d.inHours;
    if (hours < 48) return '$hours hours';
    final int days = d.inDays;
    return '$days days';
  }
}

/// Tenant-side post-completion confirmation. Asks whether the issue is
/// actually fixed and posts a confirmation comment back into the thread.
class TenantConfirmationCard extends ConsumerStatefulWidget {
  const TenantConfirmationCard({required this.request, super.key});

  final MaintenanceRequest request;

  static bool isApplicable(MaintenanceRequest r) =>
      r.status == RequestStatus.completed;

  @override
  ConsumerState<TenantConfirmationCard> createState() =>
      _TenantConfirmationCardState();
}

class _TenantConfirmationCardState
    extends ConsumerState<TenantConfirmationCard> {
  bool _submitting = false;

  Future<void> _confirm({required bool fixed}) async {
    setState(() => _submitting = true);
    final String text = fixed
        ? 'Tenant confirms the issue is fixed. Thanks!'
        : 'Tenant reports the issue is not fully fixed.';
    final bool ok = await ref
        .read(addCommentControllerProvider.notifier)
        .submit(requestId: widget.request.id, text: text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fixed
                ? 'Thanks — your landlord has been notified.'
                : 'We let your landlord know.',
          ),
        ),
      );
      return;
    }
    final AsyncValue<void> state = ref
        .read(addCommentControllerProvider.notifier)
        .stateFor(widget.request.id);
    final Object? error = state.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is CommentsException
              ? error.message
              : 'Could not post your confirmation.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.greenDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Was this issue fixed?',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your landlord marked this complete. Let them know whether the fix worked.',
            style: text.bodySmall?.copyWith(color: AppColors.bodyText),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _submitting ? null : () => _confirm(fixed: true),
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: const Text('Yes, all fixed'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed:
                      _submitting ? null : () => _confirm(fixed: false),
                  icon: const Icon(Icons.thumb_down_alt_outlined),
                  label: const Text('Still broken'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
