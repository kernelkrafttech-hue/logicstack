import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/app_user.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/domain/property.dart';
import 'dashboard_scaffold.dart';
import 'widgets/stat_card.dart';

class LandlordDashboard extends ConsumerWidget {
  const LandlordDashboard({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> properties =
        ref.watch(myPropertiesProvider);
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
        _StatsGrid(properties: properties),
        const SizedBox(height: 24),
        Text(
          'Manage',
          style: text.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _PropertiesEntryCard(
          count: properties.valueOrNull?.length,
          loading: properties.isLoading,
          onTap: () => context.go(AppRoutes.properties),
        ),
        const SizedBox(height: 12),
        const DashboardCard(
          icon: Icons.assignment_outlined,
          title: 'Maintenance requests',
          body: 'Triage and assign incoming requests from your tenants.',
        ),
        const DashboardCard(
          icon: Icons.engineering_outlined,
          title: 'Contractors',
          body: 'Build a roster of trusted contractors for fast dispatch.',
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.properties});

  final AsyncValue<List<Property>> properties;

  @override
  Widget build(BuildContext context) {
    final int count = properties.valueOrNull?.length ?? 0;
    final bool loading = properties.isLoading && !properties.hasValue;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                label: 'Total properties',
                value: '$count',
                icon: Icons.apartment_rounded,
                loading: loading,
                onTap: () => GoRouter.of(context).go(AppRoutes.properties),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: StatCard(
                label: 'Open requests',
                value: '0',
                icon: Icons.assignment_late_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const <Widget>[
            Expanded(
              child: StatCard(
                label: 'Emergency',
                value: '0',
                icon: Icons.warning_amber_rounded,
                tone: StatTone.danger,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Completed this month',
                value: '0',
                icon: Icons.check_circle_outline_rounded,
                tone: StatTone.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PropertiesEntryCard extends StatelessWidget {
  const _PropertiesEntryCard({
    required this.count,
    required this.loading,
    required this.onTap,
  });

  final int? count;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String trailing = loading
        ? '…'
        : (count == null || count == 0)
            ? 'Add your first'
            : '$count managed';

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
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Properties',
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
