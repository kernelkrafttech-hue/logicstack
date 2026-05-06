import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import 'dashboard_scaffold.dart';

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      user: user,
      title: 'Tenant',
      subtitle:
          'Report issues quickly and follow them through to resolution from your phone.',
      children: const <Widget>[
        DashboardCard(
          icon: Icons.add_circle_outline_rounded,
          title: 'Report an issue',
          body: 'Snap a photo, describe the problem, and we route it for you.',
        ),
        DashboardCard(
          icon: Icons.history_rounded,
          title: 'My requests',
          body: 'Track the status of every request you have submitted.',
        ),
        DashboardCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Messages',
          body: 'Coordinate scheduling with your landlord and contractors.',
        ),
      ],
    );
  }
}
