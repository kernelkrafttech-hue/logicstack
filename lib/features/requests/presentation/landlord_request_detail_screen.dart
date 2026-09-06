import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../contractors/domain/contractor.dart';
import '../../contractors/presentation/widgets/assign_contractor_sheet.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/domain/property.dart';
import '../application/request_providers.dart';
import '../data/request_repository.dart';
import '../domain/maintenance_request.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/ai_insights_section.dart';
import 'widgets/comments_section.dart';
import 'widgets/reminder_cards.dart';
import 'widgets/status_chip.dart';
import 'widgets/urgency_badge.dart';

class LandlordRequestDetailScreen extends ConsumerWidget {
  const LandlordRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MaintenanceRequest?> async =
        ref.watch(requestByIdProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.landlordRequests),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => _Message(
            icon: Icons.error_outline_rounded,
            tone: AppColors.error,
            title: 'Could not load request',
            body: '$error',
          ),
          data: (MaintenanceRequest? r) {
            if (r == null) {
              return const _Message(
                icon: Icons.search_off_rounded,
                tone: AppColors.mutedText,
                title: 'Request not found',
                body: 'It may have been removed.',
              );
            }
            return _Body(request: r);
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.request});

  final MaintenanceRequest request;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final RequestStatus? next = await showModalBottomSheet<RequestStatus>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) =>
          _StatusPicker(current: request.status),
    );
    if (next == null || next == request.status) return;
    if (!context.mounted) return;

    final bool ok = await ref
        .read(updateRequestStatusControllerProvider.notifier)
        .setStatus(id: request.id, status: next);

    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated to ${next.displayName}.')),
      );
      return;
    }
    final AsyncValue<void> state =
        ref.read(updateRequestStatusControllerProvider);
    final Object? error = state.error;
    final String message = error is RequestException
        ? error.message
        : 'Could not update status. Please try again.';
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
    final AsyncValue<Property?> property =
        ref.watch(propertyByIdProvider(request.propertyId));
    final bool updating =
        ref.watch(updateRequestStatusControllerProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        _HeroCard(request: request),
        if (ContractorWaitingReminder.isApplicable(request)) ...<Widget>[
          const SizedBox(height: 12),
          ContractorWaitingReminder(request: request),
        ],
        const SizedBox(height: 24),
        _SectionHeader(label: 'Status'),
        const SizedBox(height: 8),
        _StatusActionRow(
          status: request.status,
          loading: updating,
          onChange: () => _changeStatus(context, ref),
        ),
        const SizedBox(height: 24),
        _SectionHeader(label: 'Property'),
        const SizedBox(height: 8),
        _PropertyTile(async: property),
        const SizedBox(height: 24),
        AiInsightsSection(request: request),
        const SizedBox(height: 24),
        _ContractorSection(request: request),
        const SizedBox(height: 24),
        _SectionHeader(label: 'Tenant'),
        const SizedBox(height: 8),
        _DetailRow(
          label: 'Tenant ID',
          value: request.tenantId.isEmpty ? '—' : request.tenantId,
          mono: true,
        ),
        const SizedBox(height: 24),
        if (request.description.isNotEmpty) ...<Widget>[
          _SectionHeader(label: 'Description'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              request.description,
              style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (request.photoUrls.isNotEmpty) ...<Widget>[
          _SectionHeader(label: 'Photos'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (final String url in request.photoUrls)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (
                      BuildContext _,
                      Widget child,
                      ImageChunkEvent? progress,
                    ) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.lightGray,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.lightGray,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        ActivityTimeline(requestId: request.id),
        const SizedBox(height: 24),
        CommentsSection(requestId: request.id),
        const SizedBox(height: 24),
        _SectionHeader(label: 'Timestamps'),
        const SizedBox(height: 8),
        _DetailRow(label: 'Submitted', value: _formatDate(request.createdAt)),
        _DetailRow(
          label: 'Last updated',
          value: _formatDate(request.updatedAt),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMMd().add_jm().format(date.toLocal());
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.request});
  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
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
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  request.category.icon,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      request.title,
                      style: text.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.category.displayName,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.lightGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              StatusChip(status: request.status),
              UrgencyBadge(urgency: request.urgency),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContractorSection extends ConsumerWidget {
  const _ContractorSection({required this.request});

  final MaintenanceRequest request;

  Future<void> _pickAndAssign(BuildContext context, WidgetRef ref) async {
    final Contractor? picked = await showAssignContractorSheet(
      context,
      currentContractorId: request.contractorId,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    if (picked.id == request.contractorId) return;

    final bool ok = await ref
        .read(assignContractorControllerProvider.notifier)
        .assign(requestId: request.id, contractor: picked);

    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to ${picked.name}.')),
      );
      return;
    }
    final AsyncValue<void> state =
        ref.read(assignContractorControllerProvider);
    final Object? error = state.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is RequestException
              ? error.message
              : 'Could not assign contractor.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool busy =
        ref.watch(assignContractorControllerProvider).isLoading;
    final bool assigned = request.hasContractorAssigned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.engineering_rounded,
              color: AppColors.greenDark,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Contractor',
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
              onPressed: busy ? null : () => _pickAndAssign(context, ref),
              icon: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(assigned ? 'Reassign' : 'Assign'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (assigned) _AssignedCard(request: request) else const _UnassignedCard(),
      ],
    );
  }
}

class _AssignedCard extends StatelessWidget {
  const _AssignedCard({required this.request});
  final MaintenanceRequest request;

  String _formatAssignedAt() {
    final DateTime? a = request.assignedAt;
    if (a == null) return '';
    return DateFormat.yMMMd().add_jm().format(a.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String tradeLabel = request.contractorTrade ?? '';
    final String when = _formatAssignedAt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.engineering_rounded,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  request.contractorName ?? '—',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                if (tradeLabel.isNotEmpty)
                  Text(
                    tradeLabel,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.bodyText,
                    ),
                  ),
                if (request.contractorEmail?.isNotEmpty == true)
                  SelectableText(
                    request.contractorEmail!,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                if (when.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned $when',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnassignedCard extends StatelessWidget {
  const _UnassignedCard();

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
          const Icon(
            Icons.person_outline_rounded,
            color: AppColors.mutedText,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No contractor assigned yet. Tap Assign to pick from your '
              'roster — the request will move to "Sent to contractor" '
              'automatically.',
              style: text.bodyMedium?.copyWith(color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionRow extends StatelessWidget {
  const _StatusActionRow({
    required this.status,
    required this.loading,
    required this.onChange,
  });

  final RequestStatus status;
  final bool loading;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: StatusChip(status: status)),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: loading ? null : onChange,
            icon: loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.current});
  final RequestStatus current;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Update status',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            const Divider(height: 1),
            for (final RequestStatus s in RequestStatus.values)
              ListTile(
                leading: StatusChip(status: s, dense: true),
                title: Text(s.displayName),
                trailing: s == current
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.greenDark,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({required this.async});
  final AsyncValue<Property?> async;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return async.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: const <Widget>[
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading property…'),
          ],
        ),
      ),
      error: (Object e, _) => _PropertyPlaceholder(
        text: 'Could not load property.',
        tone: AppColors.error,
      ),
      data: (Property? p) {
        if (p == null) {
          return _PropertyPlaceholder(
            text: 'Property unavailable.',
            tone: AppColors.mutedText,
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      p.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.streetLine,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.bodyText,
                      ),
                    ),
                    Text(
                      p.cityLine,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PropertyPlaceholder extends StatelessWidget {
  const _PropertyPlaceholder({required this.text, required this.tone});
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: tone, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: (mono
                      ? text.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.bodyText,
                        )
                      : text.bodyMedium?.copyWith(
                          color: AppColors.bodyText,
                          fontWeight: FontWeight.w500,
                        )) ??
                  const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: tone, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
