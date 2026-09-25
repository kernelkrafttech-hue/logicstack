import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/contractor_providers.dart';
import '../../domain/contractor.dart';

/// Bottom-sheet picker that returns the chosen [Contractor] (or `null`).
///
/// The caller is responsible for calling the assign controller — this
/// widget is purely a picker so the same UI can be reused for re-assigning.
Future<Contractor?> showAssignContractorSheet(
  BuildContext context, {
  String? currentContractorId,
}) {
  return showModalBottomSheet<Contractor>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) => _AssignContractorSheet(
      currentContractorId: currentContractorId,
    ),
  );
}

class _AssignContractorSheet extends ConsumerWidget {
  const _AssignContractorSheet({this.currentContractorId});

  final String? currentContractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Contractor>> async =
        ref.watch(myContractorsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Assign contractor',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (Object error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load contractors: $error',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (List<Contractor> list) {
                    if (list.isEmpty) {
                      return _EmptyRoster(
                        onAdd: () {
                          Navigator.of(context).pop();
                          GoRouter.of(context).go(AppRoutes.contractorNew);
                        },
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext _, int i) {
                        final Contractor c = list[i];
                        final bool current = c.id == currentContractorId;
                        return ListTile(
                          leading: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(c.trade.icon, color: AppColors.navy),
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            c.companyName.isEmpty
                                ? c.trade.displayName
                                : '${c.companyName} · ${c.trade.displayName}',
                          ),
                          trailing: current
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.greenDark,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.engineering_rounded,
            size: 32,
            color: AppColors.navy,
          ),
          const SizedBox(height: 10),
          Text(
            'No contractors yet',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a contractor to assign jobs from this screen.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add contractor'),
          ),
        ],
      ),
    );
  }
}
