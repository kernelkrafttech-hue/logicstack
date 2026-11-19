import 'package:flutter/material.dart';

import '../../domain/maintenance_request.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.status,
    this.dense = false,
    super.key,
  });

  final RequestStatus status;

  /// Tightens padding for inline card use.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
