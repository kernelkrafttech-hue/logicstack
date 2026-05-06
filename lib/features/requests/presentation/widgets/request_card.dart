import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/maintenance_request.dart';
import 'urgency_badge.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.request,
    required this.onTap,
    super.key,
  });

  final MaintenanceRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(request.category.icon, color: AppColors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          request.title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.category.displayName} · ${request.status.displayName}',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  UrgencyBadge(urgency: request.urgency),
                ],
              ),
              if (request.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  request.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: AppColors.bodyText),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  if (request.photoUrls.isNotEmpty) ...<Widget>[
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request.photoUrls.length}',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _formatTimestamp(request.createdAt),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Just now';
    return DateFormat.MMMd().add_jm().format(date.toLocal());
  }
}
