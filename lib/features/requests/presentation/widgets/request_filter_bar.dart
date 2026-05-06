import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/maintenance_request.dart';

/// Filters a landlord can apply to the maintenance requests list.
enum RequestFilter {
  all('All'),
  emergency('Emergency'),
  open('Open'),
  completed('Completed');

  const RequestFilter(this.label);
  final String label;

  bool matches(MaintenanceRequest r) {
    switch (this) {
      case RequestFilter.all:
        return true;
      case RequestFilter.emergency:
        return r.urgency == RequestUrgency.emergency && r.status.isOpen;
      case RequestFilter.open:
        return r.status.isOpen;
      case RequestFilter.completed:
        return r.status == RequestStatus.completed;
    }
  }
}

/// Horizontal scrollable choice chips for filtering the requests list.
class RequestFilterBar extends StatelessWidget {
  const RequestFilterBar({
    required this.selected,
    required this.onChanged,
    required this.counts,
    super.key,
  });

  final RequestFilter selected;
  final ValueChanged<RequestFilter> onChanged;
  final Map<RequestFilter, int> counts;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          for (final RequestFilter filter in RequestFilter.values) ...<Widget>[
            ChoiceChip(
              selected: filter == selected,
              onSelected: (_) => onChanged(filter),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.navy,
              side: BorderSide(
                color: filter == selected
                    ? AppColors.navy
                    : AppColors.border,
              ),
              shape: const StadiumBorder(),
              labelStyle: text.labelLarge?.copyWith(
                color: filter == selected
                    ? AppColors.white
                    : AppColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
              label: Text(
                '${filter.label} · ${counts[filter] ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
