import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/app_user.dart';
import '../../contractors/application/contractor_providers.dart';
import '../../contractors/domain/contractor.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/domain/property.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/domain/maintenance_request.dart';
import '../../requests/presentation/widgets/request_filter_bar.dart';
import 'dashboard_scaffold.dart';
import 'widgets/stat_card.dart';

class LandlordDashboard extends ConsumerWidget {
  const LandlordDashboard({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> properties =
        ref.watch(myPropertiesProvider);
    final AsyncValue<List<MaintenanceRequest>> requests =
        ref.watch(landlordRequestsProvider);
    final AsyncValue<List<Contractor>> contractors =
        ref.watch(myContractorsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return DashboardScaffold(
      user: user,
      title: 'Landlord',
      subtitle:
          'Track your properties, tenants, and incoming maintenance work in one place.',
      children: <Widget>[
        Text(
          'Overview',
          style: text.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _StatsGrid(properties: properties, requests: requests),
        const SizedBox(height: 24),
        Text(
          'Manage',
          style: text.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          icon: Icons.apartment_rounded,
          title: 'Properties',
          trailing: _propertiesTrailing(properties),
          onTap: () => context.go(AppRoutes.properties),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          icon: Icons.assignment_outlined,
          title: 'Maintenance requests',
          trailing: _requestsTrailing(requests),
          onTap: () => context.go(AppRoutes.landlordRequests),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          icon: Icons.engineering_outlined,
          title: 'Contractors',
          trailing: _contractorsTrailing(contractors),
          onTap: () => context.go(AppRoutes.contractors),
        ),
      ],
    );
  }

  String _propertiesTrailing(AsyncValue<List<Property>> p) {
    if (p.isLoading && !p.hasValue) return '…';
    final int n = p.valueOrNull?.length ?? 0;
    if (n == 0) return 'Add your first';
    return '$n managed';
  }

  String _requestsTrailing(AsyncValue<List<MaintenanceRequest>> r) {
    if (r.isLoading && !r.hasValue) return '…';
    final List<MaintenanceRequest> list = r.valueOrNull ?? <MaintenanceRequest>[];
    if (list.isEmpty) return 'Nothing yet';
    final int open = list.where((MaintenanceRequest x) => x.status.isOpen).length;
    return '$open open · ${list.length} total';
  }

  String _contractorsTrailing(AsyncValue<List<Contractor>> c) {
    if (c.isLoading && !c.hasValue) return '…';
    final int n = c.valueOrNull?.length ?? 0;
    if (n == 0) return 'Add your first';
    return '$n in roster';
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.properties, required this.requests});

  final AsyncValue<List<Property>> properties;
  final AsyncValue<List<MaintenanceRequest>> requests;

  @override
  Widget build(BuildContext context) {
    final List<MaintenanceRequest> list =
        requests.valueOrNull ?? <MaintenanceRequest>[];
    final bool propsLoading = properties.isLoading && !properties.hasValue;
    final bool reqsLoading = requests.isLoading && !requests.hasValue;

    final int totalProperties = properties.valueOrNull?.length ?? 0;
    final int openCount =
        list.where((MaintenanceRequest r) => r.status.isOpen).length;
    final int emergencyCount = list
        .where((MaintenanceRequest r) =>
            r.urgency == RequestUrgency.emergency && r.status.isOpen)
        .length;

    final DateTime now = DateTime.now();
    final int completedThisMonth = list.where((MaintenanceRequest r) {
      if (r.status != RequestStatus.completed) return false;
      final DateTime? when = r.updatedAt;
      if (when == null) return false;
      return when.year == now.year && when.month == now.month;
    }).length;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                label: 'Total properties',
                value: '$totalProperties',
                icon: Icons.apartment_rounded,
                loading: propsLoading,
                onTap: () => GoRouter.of(context).go(AppRoutes.properties),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Open requests',
                value: '$openCount',
                icon: Icons.assignment_late_outlined,
                loading: reqsLoading,
                onTap: () => GoRouter.of(context).go(
                  AppRoutes.landlordRequestsWithFilter(RequestFilter.open),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                label: 'Emergency',
                value: '$emergencyCount',
                icon: Icons.warning_amber_rounded,
                tone: StatTone.danger,
                loading: reqsLoading,
                onTap: () => GoRouter.of(context).go(
                  AppRoutes.landlordRequestsWithFilter(RequestFilter.emergency),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Completed this month',
                value: '$completedThisMonth',
                icon: Icons.check_circle_outline_rounded,
                tone: StatTone.success,
                loading: reqsLoading,
                onTap: () => GoRouter.of(context).go(
                  AppRoutes.landlordRequestsWithFilter(RequestFilter.completed),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.greenSoft : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.greenDark : AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trailing,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
