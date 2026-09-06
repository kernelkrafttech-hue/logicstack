import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      lastUpdated: 'January 2026',
      sections: <LegalSection>[
        LegalSection(
          heading: 'What we collect',
          body:
              'Account information you give us (name, email, phone, role, '
              'optional company and photo), the maintenance requests you '
              'create, comments you post, photos you upload, and metadata '
              'about how you use the app.',
        ),
        LegalSection(
          heading: 'Why we collect it',
          body:
              'To provide the service: routing requests between landlords, '
              'tenants, and contractors; running AI triage on requests when '
              'your plan includes it; sending notifications about activity '
              'that affects you; processing payments via Stripe.',
        ),
        LegalSection(
          heading: 'Who we share it with',
          body:
              'We share request data with the parties involved in that '
              'request (the landlord, tenant, and assigned contractor). '
              'We use Firebase, Google Cloud, OpenAI, and Stripe as '
              'sub-processors. We don\'t sell your data.',
        ),
        LegalSection(
          heading: 'Retention and deletion',
          body:
              'You can delete your account at any time from Settings → '
              'Delete account. We remove your profile and authentication '
              'record on request. Maintenance requests you authored may be '
              'retained where another party has an active matter open.',
        ),
        LegalSection(
          heading: 'Security',
          body:
              'Data in transit is encrypted with TLS. Firestore and Storage '
              'access is gated by per-collection security rules tested on '
              'every release.',
        ),
        LegalSection(
          heading: 'Contact',
          body:
              'Privacy questions or data subject requests: '
              'privacy@maintenanceos.app.',
        ),
      ],
    );
  }
}
