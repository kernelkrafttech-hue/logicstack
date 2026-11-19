import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_retry_view.dart';
import '../../../shared/widgets/shimmer.dart';
import '../application/property_providers.dart';
import '../domain/property.dart';
import 'widgets/property_card.dart';

class PropertiesListScreen extends ConsumerWidget {
  const PropertiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> properties =
        ref.watch(myPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.landlord),
        ),
      ),
      floatingActionButton: properties.maybeWhen(
        data: (List<Property> list) => list.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.go(AppRoutes.propertyNew),
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add property'),
              ),
        orElse: () => null,
      ),
      body: SafeArea(
        child: properties.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SkeletonList(count: 4),
          ),
          error: (Object error, _) => ErrorRetryView(
            message: '$error',
            onRetry: () => ref.invalidate(myPropertiesProvider),
          ),
          data: (List<Property> list) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myPropertiesProvider);
                await Future<void>.delayed(
                  const Duration(milliseconds: 250),
                );
              },
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[_EmptyState()],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      itemBuilder: (BuildContext context, int index) {
                        final Property property = list[index];
                        return PropertyCard(
                          property: property,
                          onTap: () => context.go(
                            AppRoutes.propertyDetailFor(property.id),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: list.length,
                    ),
            );
          },
        ),
      ),
    );
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
                Icons.apartment_rounded,
                size: 32,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No properties yet',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first property to start coordinating maintenance.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.propertyNew),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add property'),
            ),
          ],
        ),
      ),
    );
  }
}

