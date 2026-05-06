import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import 'dashboard_scaffold.dart';

class ContractorDashboard extends StatelessWidget {
  const ContractorDashboard({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      user: user,
      title: 'Contractor',
      subtitle:
          'See incoming jobs, accept work, and keep tenants and landlords in the loop.',
      children: const <Widget>[
        DashboardCard(
          icon: Icons.inbox_outlined,
          title: 'Job inbox',
          body: 'Review new dispatches from landlords and accept work.',
        ),
        DashboardCard(
          icon: Icons.calendar_today_outlined,
          title: 'Schedule',
          body: 'Manage your appointments and on-site visits.',
        ),
        DashboardCard(
          icon: Icons.receipt_long_outlined,
          title: 'Invoices',
          body: 'Issue invoices and track payments per job.',
        ),
      ],
    );
  }
}
