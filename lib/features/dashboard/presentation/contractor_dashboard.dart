import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/app_user.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/domain/maintenance_request.dart';
import '../../requests/presentation/widgets/request_card.dart';
import 'dashboard_scaffold.dart';

class ContractorDashboard extends ConsumerWidget {
  const ContractorDashboard({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MaintenanceRequest>> jobs =
        ref.watch(contractorJobsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final List<MaintenanceRequest> all = jobs.valueOrNull ?? const <MaintenanceRequest>[];
    final int openCount =
        all.where((MaintenanceRequest j) => j.status.isOpen).length;

    return DashboardScaffold(
      user: user,
      title: 'Contractor',
      subtitle:
          'Jobs assigned to your email show up here. Update status as you work.',
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'My jobs',
              style: text.titleMedium?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            jobs.maybeWhen(
              data: (List<MaintenanceRequest> list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      '$openCount open · ${list.length} total',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _JobsList(jobs: jobs),
      ],
    );
  }
}

class _JobsList extends StatelessWidget {
  const _JobsList({required this.jobs});

  final AsyncValue<List<MaintenanceRequest>> jobs;

  @override
  Widget build(BuildContext context) {
    return jobs.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, _) => _ErrorState(message: '$error'),
      data: (List<MaintenanceRequest> list) {
        if (list.isEmpty) return const _EmptyState();
        return Column(
          children: <Widget>[
            for (int i = 0; i < list.length; i++) ...<Widget>[
              if (i != 0) const SizedBox(height: 12),
              RequestCard(
                request: list[i],
                onTap: () => GoRouter.of(context).go(
                  AppRoutes.contractorJobDetailFor(list[i].id),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: AppColors.navy,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No jobs assigned yet',
            style: text.titleSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When a landlord assigns work to your email, it will show up here.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.bodyText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
