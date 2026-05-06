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
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/subscription.dart';
import '../../billing/presentation/widgets/upgrade_banner.dart';
import '../application/property_providers.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _zipCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _unitCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AppUser? user = ref.read(appUserProvider).valueOrNull;
    if (user == null) {
      _showError('You must be signed in to add a property.');
      return;
    }
    final Subscription? subscription =
        ref.read(subscriptionProvider).valueOrNull;
    final List<Property> existing =
        ref.read(myPropertiesProvider).valueOrNull ?? const <Property>[];
    final GateResult gate = checkCanAddProperty(
      subscription: subscription,
      currentPropertyCount: existing.length,
    );
    if (!gate.allowed) {
      _showError(gate.reason);
      return;
    }
    FocusScope.of(context).unfocus();

    final Property? created =
        await ref.read(addPropertyControllerProvider.notifier).submit(
              ownerId: user.uid,
              name: _nameCtrl.text,
              address: _addressCtrl.text,
              unit: _unitCtrl.text,
              city: _cityCtrl.text,
              state: _stateCtrl.text,
              zipCode: _zipCtrl.text,
            );

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added.')),
      );
      context.go(AppRoutes.propertyDetailFor(created.id));
      return;
    }

    final AsyncValue<void> state = ref.read(addPropertyControllerProvider);
    final Object? error = state.error;
    _showError(
      error is PropertyException
          ? error.message
          : 'Could not save property. Please try again.',
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
    final AsyncValue<void> state = ref.watch(addPropertyControllerProvider);
    final bool loading = state.isLoading;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add property'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.properties),
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
                _PlanGateBanner(),
                Text(
                  'Property details',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Give it a memorable name and the full mailing address.',
                  style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _nameCtrl,
                  label: 'Property name',
                  hintText: 'Maple Street Duplex',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.home_work_outlined,
                  validator: (String? v) =>
                      Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _addressCtrl,
                  label: 'Street address',
                  hintText: '123 Maple St',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.location_on_outlined,
                  autofillHints: const <String>[
                    AutofillHints.streetAddressLine1,
                  ],
                  validator: (String? v) =>
                      Validators.required(v, field: 'Address'),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _unitCtrl,
                  label: 'Unit (optional)',
                  hintText: 'Apt 2B',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.door_front_door_outlined,
                  autofillHints: const <String>[
                    AutofillHints.streetAddressLine2,
                  ],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _cityCtrl,
                  label: 'City',
                  hintText: 'Oakland',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.location_city_outlined,
                  autofillHints: const <String>[
                    AutofillHints.addressCity,
                  ],
                  validator: (String? v) =>
                      Validators.required(v, field: 'City'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: _StateField(controller: _stateCtrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AuthTextField(
                        controller: _zipCtrl,
                        label: 'ZIP code',
                        hintText: '94607',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.markunread_mailbox_outlined,
                        autofillHints: const <String>[
                          AutofillHints.postalCode,
                        ],
                        validator: Validators.zipCode,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Save property',
                  loading: loading,
                  onPressed: _submit,
                  icon: Icons.check_rounded,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed:
                      loading ? null : () => context.go(AppRoutes.properties),
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

class _StateField extends StatelessWidget {
  const _StateField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      label: 'State',
      hintText: 'CA',
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.flag_outlined,
      validator: Validators.usState,
      autofillHints: const <String>[AutofillHints.addressState],
    );
  }
}

/// Inline banner shown above the form when the current plan's property
/// limit has been hit.
class _PlanGateBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Subscription? sub = ref.watch(subscriptionProvider).valueOrNull;
    final List<Property> existing =
        ref.watch(myPropertiesProvider).valueOrNull ?? const <Property>[];
    final GateResult gate = checkCanAddProperty(
      subscription: sub,
      currentPropertyCount: existing.length,
    );
    if (gate.allowed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UpgradeBanner(
        message: gate.reason,
        suggestedPlan: gate.suggestedPlan,
      ),
    );
  }
}
