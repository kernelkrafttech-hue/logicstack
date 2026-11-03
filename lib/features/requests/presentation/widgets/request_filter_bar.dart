import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/maintenance_request.dart';

/// Filters a landlord can apply to the maintenance requests list. Each
/// filter resolves either a status predicate or a category predicate; the
/// `all` filter is the identity.
enum RequestFilter {
  all('All'),
  emergency('Emergency'),
  open('Open'),
  completed('Completed'),
  plumbing('Plumbing', category: RequestCategory.plumbing),
  electrical('Electrical', category: RequestCategory.electrical),
  hvac('HVAC', category: RequestCategory.hvac);

  const RequestFilter(this.label, {this.category});

  final String label;
  final RequestCategory? category;

  bool matches(MaintenanceRequest r) {
    if (category != null) return r.category == category;
    switch (this) {
      case RequestFilter.all:
        return true;
      case RequestFilter.emergency:
        return r.urgency == RequestUrgency.emergency && r.status.isOpen;
      case RequestFilter.open:
        return r.status.isOpen;
      case RequestFilter.completed:
        return r.status == RequestStatus.completed;
      case RequestFilter.plumbing:
      case RequestFilter.electrical:
      case RequestFilter.hvac:
        return false; // unreachable — handled by `category` branch above
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          for (final RequestFilter filter in RequestFilter.values) ...<Widget>[
            ChoiceChip(
              selected: filter == selected,
              onSelected: (_) => onChanged(filter),
              backgroundColor: isDark ? AppColors.navy : AppColors.surface,
              selectedColor: isDark ? AppColors.green : AppColors.navy,
              side: BorderSide(
                color: filter == selected
                    ? (isDark ? AppColors.green : AppColors.navy)
                    : AppColors.border,
              ),
              shape: const StadiumBorder(),
              labelStyle: text.labelLarge?.copyWith(
                color: filter == selected
                    ? AppColors.white
                    : (isDark ? AppColors.white : AppColors.bodyText),
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
