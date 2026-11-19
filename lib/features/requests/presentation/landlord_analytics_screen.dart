import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../application/request_providers.dart';
import '../domain/maintenance_request.dart';

/// Landlord-side analytics: aggregate stats over the full request set
/// (capped at 500 by [landlordAllRequestsProvider]) so trends like average
/// completion time stay meaningful as the queue grows.
class LandlordAnalyticsScreen extends ConsumerWidget {
  const LandlordAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MaintenanceRequest>> async =
        ref.watch(landlordAllRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.landlord),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: SkeletonList(count: 4),
          ),
          error: (Object error, _) => ErrorRetryView(
            message: '$error',
            onRetry: () => ref.invalidate(landlordAllRequestsProvider),
          ),
          data: (List<MaintenanceRequest> all) => _Body(requests: all),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.requests});
  final List<MaintenanceRequest> requests;

  Duration? get _averageCompletion {
    final List<Duration> durations = <Duration>[];
    for (final MaintenanceRequest r in requests) {
      if (r.status != RequestStatus.completed) continue;
      final DateTime? created = r.createdAt;
      final DateTime? closed = r.updatedAt;
      if (created == null || closed == null) continue;
      durations.add(closed.difference(created));
    }
    if (durations.isEmpty) return null;
    final int totalMs = durations
        .map((Duration d) => d.inMilliseconds)
        .reduce((int a, int b) => a + b);
    return Duration(milliseconds: (totalMs / durations.length).round());
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int total = requests.length;
    final int open = requests
        .where((MaintenanceRequest r) => r.status.isOpen)
        .length;
    final int emergency = requests
        .where((MaintenanceRequest r) =>
            r.urgency == RequestUrgency.emergency && r.status.isOpen)
        .length;
    final int completed = requests
        .where((MaintenanceRequest r) => r.status == RequestStatus.completed)
        .length;

    final Map<RequestCategory, int> byCategory = <RequestCategory, int>{
      for (final RequestCategory c in RequestCategory.values)
        c: requests.where((MaintenanceRequest r) => r.category == c).length,
    };
    final List<MapEntry<RequestCategory, int>> categories = byCategory.entries
        .where((MapEntry<RequestCategory, int> e) => e.value > 0)
        .toList(growable: false)
      ..sort((MapEntry<RequestCategory, int> a, MapEntry<RequestCategory, int> b) =>
          b.value.compareTo(a.value));
    final int maxCategory = categories.isEmpty
        ? 0
        : categories.first.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        Text(
          'Overview',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _Stat(
                label: 'Avg completion',
                value: _formatDuration(_averageCompletion),
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Open',
                value: '$open',
                icon: Icons.assignment_late_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _Stat(
                label: 'Emergency',
                value: '$emergency',
                icon: Icons.warning_amber_rounded,
                tone: StatTone.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Completed',
                value: '$completed',
                icon: Icons.check_circle_outline_rounded,
                tone: StatTone.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'By category',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('No data yet.'),
          )
        else
          for (final MapEntry<RequestCategory, int> entry in categories)
            _CategoryBar(
              category: entry.key,
              count: entry.value,
              total: total,
              max: maxCategory,
            ),
      ],
    );
  }
}

enum StatTone { neutral, success, danger }

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatTone.neutral,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatTone tone;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ({Color bg, Color fg}) tones = switch (tone) {
      StatTone.success => (bg: AppColors.greenSoft, fg: AppColors.greenDark),
      StatTone.danger => (bg: const Color(0xFFFCE7E7), fg: AppColors.error),
      StatTone.neutral => (bg: AppColors.lightGray, fg: AppColors.navy),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: tones.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tones.fg, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.count,
    required this.total,
    required this.max,
  });

  final RequestCategory category;
  final int count;
  final int total;
  final int max;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double ratio = max == 0 ? 0 : count / max;
    final double percent = total == 0 ? 0 : count / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(category.icon, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.displayName,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count · ${(percent * 100).toStringAsFixed(0)}%',
                style: text.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.lightGray,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}
