import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/request_providers.dart';
import '../domain/maintenance_request.dart';
import 'widgets/request_card.dart';
import 'widgets/request_filter_bar.dart';

class MaintenanceRequestsScreen extends ConsumerStatefulWidget {
  const MaintenanceRequestsScreen({this.initialFilter, super.key});

  /// Optional filter to apply when arriving from a dashboard stat card.
  final RequestFilter? initialFilter;

  @override
  ConsumerState<MaintenanceRequestsScreen> createState() =>
      _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState
    extends ConsumerState<MaintenanceRequestsScreen> {
  late RequestFilter _filter = widget.initialFilter ?? RequestFilter.all;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MaintenanceRequest>> async =
        ref.watch(landlordRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.landlord),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => _ErrorState(message: '$error'),
          data: (List<MaintenanceRequest> all) {
            final Map<RequestFilter, int> counts = <RequestFilter, int>{
              for (final RequestFilter f in RequestFilter.values)
                f: all.where(f.matches).length,
            };
            final List<MaintenanceRequest> filtered =
                all.where(_filter.matches).toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 12),
                RequestFilterBar(
                  selected: _filter,
                  counts: counts,
                  onChanged: (RequestFilter f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(filter: _filter, total: all.length)
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int i) {
                            final MaintenanceRequest r = filtered[i];
                            return RequestCard(
                              request: r,
                              onTap: () => context.go(
                                AppRoutes.landlordRequestDetailFor(r.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.total});

  final RequestFilter filter;
  final int total;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool nothingAtAll = total == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.navy,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              nothingAtAll
                  ? 'No requests yet'
                  : 'No ${filter.label.toLowerCase()} requests',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nothingAtAll
                  ? 'When tenants submit issues for your properties, they will show up here.'
                  : 'Try a different filter to see everything.',
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
