import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../application/contractor_providers.dart';
import '../data/contractor_repository.dart';
import '../domain/contractor.dart';

/// Handles both "Add contractor" and "Edit contractor" — when [existing] is
/// non-null the form is pre-filled and the controller's [save] path runs
/// instead of [create].
class AddContractorScreen extends ConsumerStatefulWidget {
  const AddContractorScreen({this.existing, super.key});

  final Contractor? existing;

  @override
  ConsumerState<AddContractorScreen> createState() =>
      _AddContractorScreenState();
}

class _AddContractorScreenState extends ConsumerState<AddContractorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late ContractorTrade _trade;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Contractor? existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _companyCtrl = TextEditingController(text: existing?.companyName ?? '');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _emailCtrl = TextEditingController(text: existing?.email ?? '');
    _trade = existing?.trade ?? ContractorTrade.general;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AppUser? user = ref.read(appUserProvider).valueOrNull;
    if (user == null) {
      _showError('You must be signed in.');
      return;
    }
    FocusScope.of(context).unfocus();

    final ContractorFormController ctrl =
        ref.read(contractorFormControllerProvider.notifier);

    if (_isEditing) {
      final Contractor updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        trade: _trade,
      );
      final bool ok = await ctrl.save(updated);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contractor updated.')),
        );
        context.go(AppRoutes.contractorDetailFor(updated.id));
      } else {
        _showStateError();
      }
      return;
    }

    final Contractor? created = await ctrl.create(
      landlordId: user.uid,
      name: _nameCtrl.text,
      companyName: _companyCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      trade: _trade,
    );
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contractor added.')),
      );
      context.go(AppRoutes.contractorDetailFor(created.id));
    } else {
      _showStateError();
    }
  }

  void _showStateError() {
    final AsyncValue<void> state = ref.read(contractorFormControllerProvider);
    final Object? error = state.error;
    _showError(
      error is ContractorException
          ? error.message
          : 'Could not save contractor.',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> state = ref.watch(contractorFormControllerProvider);
    final bool loading = state.isLoading;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit contractor' : 'Add contractor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: loading
              ? null
              : () {
                  if (_isEditing) {
                    context.go(
                      AppRoutes.contractorDetailFor(widget.existing!.id),
                    );
                  } else {
                    context.go(AppRoutes.contractors);
                  }
                },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _isEditing ? 'Update details' : 'Contractor details',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Email is used to surface jobs in this contractor\'s '
                  'dashboard once they sign in.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _nameCtrl,
                  label: 'Full name',
                  hintText: 'Jane Doe',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (String? v) =>
                      Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _companyCtrl,
                  label: 'Company (optional)',
                  hintText: 'Doe Plumbing Co.',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _phoneCtrl,
                  label: 'Phone',
                  hintText: '(555) 123-4567',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.phone_outlined,
                  validator: (String? v) =>
                      Validators.required(v, field: 'Phone'),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hintText: 'jane@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                _TradeDropdown(
                  selected: _trade,
                  onChanged: (ContractorTrade t) => setState(() => _trade = t),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Add contractor',
                  loading: loading,
                  onPressed: _submit,
                  icon: Icons.check_rounded,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          if (_isEditing) {
                            context.go(
                              AppRoutes.contractorDetailFor(
                                widget.existing!.id,
                              ),
                            );
                          } else {
                            context.go(AppRoutes.contractors);
                          }
                        },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TradeDropdown extends StatelessWidget {
  const _TradeDropdown({required this.selected, required this.onChanged});

  final ContractorTrade selected;
  final ValueChanged<ContractorTrade> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Trade',
          style: text.labelLarge?.copyWith(
            color: AppColors.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ContractorTrade>(
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.engineering_outlined,
              color: AppColors.mutedText,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ContractorTrade.values
              .map(
                (ContractorTrade t) => DropdownMenuItem<ContractorTrade>(
                  value: t,
                  child: Row(
                    children: <Widget>[
                      Icon(t.icon, size: 18, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Text(t.displayName),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (ContractorTrade? v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
