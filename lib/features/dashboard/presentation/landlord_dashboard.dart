import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import 'dashboard_scaffold.dart';

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      user: user,
      title: 'Landlord',
      subtitle:
          'Track your properties, tenants, and incoming maintenance work in one place.',
      children: const <Widget>[
        DashboardCard(
          icon: Icons.apartment_rounded,
          title: 'Properties',
          body: 'Add and manage the units you rent out. Coming soon.',
        ),
        DashboardCard(
          icon: Icons.assignment_outlined,
          title: 'Maintenance requests',
          body: 'Triage and assign incoming requests from your tenants.',
        ),
        DashboardCard(
          icon: Icons.engineering_outlined,
          title: 'Contractors',
          body: 'Build a roster of trusted contractors for fast dispatch.',
        ),
      ],
    );
  }
}
