import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms of Service',
      lastUpdated: 'January 2026',
      sections: <LegalSection>[
        LegalSection(
          heading: 'Acceptance',
          body:
              'By creating an account or using MaintenanceOS you agree to '
              'these terms. If you don\'t agree, don\'t use the service. '
              'These terms cover landlords, tenants, and contractors.',
        ),
        LegalSection(
          heading: 'Your account',
          body:
              'You\'re responsible for the accuracy of the information you '
              'provide and for any activity under your account. Don\'t share '
              'your credentials. Tell us right away if you suspect '
              'unauthorised access.',
        ),
        LegalSection(
          heading: 'Acceptable use',
          body:
              'Use the service for legitimate property maintenance '
              'coordination only. Don\'t upload illegal content, harass '
              'other users, or attempt to bypass our security controls.',
        ),
        LegalSection(
          heading: 'Subscriptions and refunds',
          body:
              'Paid plans renew monthly until cancelled. You can cancel any '
              'time from the Subscription screen — service continues through '
              'the end of the current billing period. We don\'t prorate '
              'partial-month refunds.',
        ),
        LegalSection(
          heading: 'Limitation of liability',
          body:
              'MaintenanceOS is provided "as is" without warranties. We are '
              'not liable for property damage, contractor performance, or '
              'tenant conduct routed through the platform.',
        ),
        LegalSection(
          heading: 'Changes',
          body:
              'We may update these terms from time to time. Material changes '
              'will be announced in-app at least 14 days before they take '
              'effect.',
        ),
        LegalSection(
          heading: 'Contact',
          body:
              'Questions about these terms? Reach us via the Support screen '
              'or at support@maintenanceos.app.',
        ),
      ],
    );
  }
}
