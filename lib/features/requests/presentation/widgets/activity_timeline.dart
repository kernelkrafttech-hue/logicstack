import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/comments_providers.dart';
import '../../domain/activity_event.dart';

/// Vertical audit timeline rendered from the request's `activity`
/// subcollection. Each event is a tinted dot connected to the next with
/// a thin rule, so the read order matches Firestore's createdAt order.
class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ActivityEvent>> async =
        ref.watch(requestActivityProvider(requestId));
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.timeline_rounded,
              size: 18,
              color: AppColors.navy,
            ),
            const SizedBox(width: 6),
            Text(
              'Activity',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        async.when(
          loading: () => const _Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (Object error, _) => _Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load activity: $error',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (List<ActivityEvent> list) {
            if (list.isEmpty) {
              return const _Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No activity yet.'),
                ),
              );
            }
            return _Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < list.length; i++)
                      _TimelineRow(
                        event: list[i],
                        isLast: i == list.length - 1,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final ActivityEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: event.type.tone,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  event.type.icon,
                  size: 16,
                  color: event.type.foreground,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.title,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  if (event.description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      event.description,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(event.createdAt),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Just now';
    return DateFormat.yMMMd().add_jm().format(date.toLocal());
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
