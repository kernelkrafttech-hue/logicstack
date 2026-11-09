import 'package:flutter/material.dart';

import '../../domain/maintenance_request.dart';

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({required this.urgency, super.key});

  final RequestUrgency urgency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgency.tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        urgency.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: urgency.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
