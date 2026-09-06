import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/contractor_providers.dart';
import '../domain/contractor.dart';
import 'widgets/contractor_card.dart';

class ContractorsListScreen extends ConsumerWidget {
  const ContractorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Contractor>> contractors =
        ref.watch(myContractorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.landlord),
        ),
      ),
      floatingActionButton: contractors.maybeWhen(
        data: (List<Contractor> list) => list.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.go(AppRoutes.contractorNew),
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add contractor'),
              ),
        orElse: () => null,
      ),
      body: SafeArea(
        child: contractors.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => _ErrorState(message: '$error'),
          data: (List<Contractor> list) {
            if (list.isEmpty) return const _EmptyState();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) {
                final Contractor c = list[i];
                return ContractorCard(
                  contractor: c,
                  onTap: () => context.go(AppRoutes.contractorDetailFor(c.id)),
                );
              },
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
                Icons.engineering_rounded,
                size: 32,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No contractors yet',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a contractor so you can dispatch maintenance work.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  GoRouter.of(context).go(AppRoutes.contractorNew),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add contractor'),
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
