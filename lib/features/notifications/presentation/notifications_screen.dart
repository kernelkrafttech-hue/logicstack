import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../application/notifications_providers.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final List<AppNotification> list =
        ref.read(myNotificationsProvider).valueOrNull ?? const <AppNotification>[];
    final List<String> unread = <String>[
      for (final AppNotification n in list)
        if (!n.read) n.id,
    ];
    if (unread.isEmpty) return;
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .markManyRead(unread);
    } on NotificationsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.read) {
      try {
        await ref.read(notificationsRepositoryProvider).markRead(n.id);
      } on NotificationsException catch (_) {
        // Best effort — even if marking fails, still navigate.
      }
    }
    if (!context.mounted) return;
    if (n.requestId == null || n.requestId!.isEmpty) return;
    final AppUser? user = ref.read(appUserProvider).valueOrNull;
    if (user == null) return;
    context.go(AppRoutes.requestDetailForRole(user.role, n.requestId!));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> async =
        ref.watch(myNotificationsProvider);
    final int unread = ref.watch(unreadNotificationCountProvider);
    final AppUser? user = ref.watch(appUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (user == null) {
              context.go(AppRoutes.login);
              return;
            }
            context.go(AppRoutes.dashboardFor(user.role));
          },
        ),
        actions: <Widget>[
          if (unread > 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
              onPressed: () => _markAllRead(context, ref),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => _ErrorState(message: '$error'),
          data: (List<AppNotification> list) {
            if (list.isEmpty) return const _EmptyState();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int i) {
                return _NotificationTile(
                  notification: list[i],
                  onTap: () => _open(context, ref, list[i]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool unread = !notification.read;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? AppColors.greenSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? AppColors.green : AppColors.border,
              width: unread ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 8,
                width: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: unread ? AppColors.green : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notification.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (notification.requestId != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Status updates, assignments, and comments will land here.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.bodyText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
