import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// Shared shell for the Terms of Service and Privacy Policy screens. The
/// content here is a starter draft — replace it with your finalised legal
/// copy before launching to real users.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.title,
    required this.lastUpdated,
    required this.sections,
    super.key,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: <Widget>[
            Text(
              title,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated $lastUpdated',
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 20),
            for (final LegalSection s in sections) ...<Widget>[
              Text(
                s.heading,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.body,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.bodyText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}
