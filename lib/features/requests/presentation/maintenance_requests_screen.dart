import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../application/request_providers.dart';
import '../domain/maintenance_request.dart';
import 'widgets/request_card.dart';
import 'widgets/request_filter_bar.dart';

class MaintenanceRequestsScreen extends ConsumerStatefulWidget {
  const MaintenanceRequestsScreen({this.initialFilter, super.key});

  final RequestFilter? initialFilter;

  @override
  ConsumerState<MaintenanceRequestsScreen> createState() =>
      _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState
    extends ConsumerState<MaintenanceRequestsScreen> {
  late RequestFilter _filter = widget.initialFilter ?? RequestFilter.all;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Iterable<MaintenanceRequest> _applyFilters(
    List<MaintenanceRequest> all,
  ) sync* {
    final String q = _query.trim().toLowerCase();
    for (final MaintenanceRequest r in all) {
      if (!_filter.matches(r)) continue;
      if (q.isNotEmpty) {
        final bool inTitle = r.title.toLowerCase().contains(q);
        final bool inBody = r.description.toLowerCase().contains(q);
        if (!inTitle && !inBody) continue;
      }
      yield r;
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(landlordRequestsProvider);
    // Wait one frame so the spinner is visible before the stream re-emits.
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MaintenanceRequest>> async =
        ref.watch(landlordRequestsProvider);
    final int pageSize = ref.watch(landlordRequestsPageSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.landlord),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchField(
                controller: _searchCtrl,
                onChanged: (String value) =>
                    setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 12),
            async.when(
              skipLoadingOnRefresh: true,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SkeletonList(count: 4),
              ),
              error: (Object error, _) => Expanded(
                child: ErrorRetryView(
                  message: '$error',
                  onRetry: () => ref.invalidate(landlordRequestsProvider),
                ),
              ),
              data: (List<MaintenanceRequest> all) {
                final Map<RequestFilter, int> counts = <RequestFilter, int>{
                  for (final RequestFilter f in RequestFilter.values)
                    f: all.where(f.matches).length,
                };
                final List<MaintenanceRequest> filtered =
                    _applyFilters(all).toList(growable: false);
                final bool hasMore = all.length >= pageSize;
                return Expanded(
                  child: Column(
                    children: <Widget>[
                      RequestFilterBar(
                        selected: _filter,
                        counts: counts,
                        onChanged: (RequestFilter f) =>
                            setState(() => _filter = f),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: filtered.isEmpty
                              ? _EmptyScrollable(
                                  filter: _filter,
                                  total: all.length,
                                  query: _query,
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    24,
                                  ),
                                  itemCount: filtered.length + (hasMore ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (BuildContext context, int i) {
                                    if (i == filtered.length) {
                                      return _LoadMoreTile(
                                        onTap: () => ref
                                                .read(
                                          landlordRequestsPageSizeProvider
                                              .notifier,
                                        )
                                            .update(
                                          (int s) =>
                                              s + landlordRequestsPageStep,
                                        ),
                                      );
                                    }
                                    final MaintenanceRequest r = filtered[i];
                                    return RequestCard(
                                      request: r,
                                      onTap: () => context.go(
                                        AppRoutes
                                            .landlordRequestDetailFor(r.id),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Search by title or description',
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.border),
      ),
      onPressed: onTap,
      icon: const Icon(Icons.expand_more_rounded),
      label: const Text('Load more'),
    );
  }
}

class _EmptyScrollable extends StatelessWidget {
  const _EmptyScrollable({
    required this.filter,
    required this.total,
    required this.query,
  });
  final RequestFilter filter;
  final int total;
  final String query;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool nothingAtAll = total == 0;
    final bool searching = query.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: <Widget>[
        Center(
          child: Container(
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
        ),
        const SizedBox(height: 14),
        Text(
          searching
              ? 'No matches'
              : nothingAtAll
                  ? 'No requests yet'
                  : 'No ${filter.label.toLowerCase()} requests',
          textAlign: TextAlign.center,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          searching
              ? 'Nothing matches "$query". Try a different keyword.'
              : nothingAtAll
                  ? 'When tenants submit issues for your properties, they will show up here.'
                  : 'Try a different filter to see everything.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
