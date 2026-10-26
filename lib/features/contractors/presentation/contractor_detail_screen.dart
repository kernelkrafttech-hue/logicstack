import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/contractor_providers.dart';
import '../data/contractor_repository.dart';
import '../domain/contractor.dart';

class ContractorDetailScreen extends ConsumerWidget {
  const ContractorDetailScreen({required this.contractorId, super.key});

  final String contractorId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Contractor contractor,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete contractor?'),
        content: Text(
          'Remove ${contractor.name} from your roster? Existing job assignments will keep the contractor\'s details on the request.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final bool ok = await ref
        .read(contractorFormControllerProvider.notifier)
        .delete(contractor.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contractor deleted.')),
      );
      context.go(AppRoutes.contractors);
      return;
    }
    final AsyncValue<void> state = ref.read(contractorFormControllerProvider);
    final Object? error = state.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ContractorException
              ? error.message
              : 'Could not delete contractor.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contractor?> async =
        ref.watch(contractorByIdProvider(contractorId));
    final bool busy =
        ref.watch(contractorFormControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.contractors),
        ),
        actions: <Widget>[
          async.maybeWhen(
            data: (Contractor? c) => c == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: busy
                        ? null
                        : () => context.go(AppRoutes.contractorEdit(c.id)),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => _Message(
            icon: Icons.error_outline_rounded,
            tone: AppColors.error,
            title: 'Could not load contractor',
            body: '$error',
          ),
          data: (Contractor? c) {
            if (c == null) {
              return const _Message(
                icon: Icons.search_off_rounded,
                tone: AppColors.mutedText,
                title: 'Contractor not found',
                body: 'It may have been removed.',
              );
            }
            return _Body(
              contractor: c,
              busy: busy,
              onDelete: () => _confirmDelete(context, ref, c),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.contractor,
    required this.busy,
    required this.onDelete,
  });

  final Contractor contractor;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(contractor.trade.icon, color: AppColors.green),
              ),
              const SizedBox(height: 14),
              Text(
                contractor.name,
                style: text.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (contractor.companyName.isNotEmpty)
                Text(
                  contractor.companyName,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contractor.trade.displayName,
                  style: text.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Contact',
          style: text.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(label: 'Phone', value: contractor.phone),
        _DetailRow(label: 'Email', value: contractor.email),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete contractor'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '—' : value,
              style: text.bodyMedium?.copyWith(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: tone, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
