import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Centred error state with a retry action. Used in place of bare error
/// text whenever an [AsyncValue] surfaces a failure.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    required this.message,
    required this.onRetry,
    this.title = 'Something went wrong',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
