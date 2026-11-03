import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/domain/property.dart';
import '../application/request_providers.dart';
import '../data/request_repository.dart';
import '../domain/maintenance_request.dart';
import 'widgets/photo_picker_grid.dart';

class SubmitRequestScreen extends ConsumerStatefulWidget {
  const SubmitRequestScreen({super.key});

  @override
  ConsumerState<SubmitRequestScreen> createState() =>
      _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends ConsumerState<SubmitRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  Property? _property;
  RequestCategory? _category;
  RequestUrgency _urgency = RequestUrgency.medium;
  List<XFile> _photos = <XFile>[];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    if (_property == null) {
      _showError('Please choose a property.');
      return;
    }
    if (_category == null) {
      _showError('Please choose a category.');
      return;
    }

    final AppUser? user = ref.read(appUserProvider).valueOrNull;
    if (user == null) {
      _showError('You must be signed in to submit a request.');
      return;
    }

    FocusScope.of(context).unfocus();

    final MaintenanceRequest? saved = await ref
        .read(submitRequestControllerProvider.notifier)
        .submit(
          propertyId: _property!.id,
          landlordId: _property!.ownerId,
          tenantId: user.uid,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category!,
          urgency: _urgency,
          photos: _photos,
        );

    if (!mounted) return;

    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted.')),
      );
      // After submission, return to "My Requests" (the tenant dashboard).
      context.go(AppRoutes.tenant);
      return;
    }

    final AsyncValue<void> state = ref.read(submitRequestControllerProvider);
    final Object? error = state.error;
    _showError(
      error is RequestException
          ? error.message
          : 'Could not submit your request. Please try again.',
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
    final AsyncValue<void> state = ref.watch(submitRequestControllerProvider);
    final bool loading = state.isLoading;
    final AsyncValue<List<Property>> properties =
        ref.watch(allPropertiesProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: loading ? null : () => context.go(AppRoutes.tenant),
        ),
      ),
      body: AbsorbPointer(
        absorbing: loading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Tell us what needs fixing',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A few details and photos help us route this faster.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PropertyDropdown(
                    properties: properties,
                    selected: _property,
                    onChanged: (Property? p) => setState(() => _property = p),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _titleCtrl,
                    label: 'Title',
                    hintText: 'Leaking kitchen faucet',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.title_rounded,
                    validator: (String? v) =>
                        Validators.required(v, field: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  _DescriptionField(controller: _descCtrl),
                  const SizedBox(height: 16),
                  _CategoryDropdown(
                    selected: _category,
                    onChanged: (RequestCategory? c) =>
                        setState(() => _category = c),
                  ),
                  const SizedBox(height: 16),
                  _UrgencyDropdown(
                    selected: _urgency,
                    onChanged: (RequestUrgency u) =>
                        setState(() => _urgency = u),
                  ),
                  const SizedBox(height: 20),
                  PhotoPickerGrid(
                    photos: _photos,
                    enabled: !loading,
                    onChanged: (List<XFile> next) =>
                        setState(() => _photos = next),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _photos.isEmpty
                        ? 'Submit request'
                        : 'Upload & submit',
                    loading: loading,
                    onPressed: _submit,
                    icon: Icons.send_rounded,
                  ),
                  if (loading) ...<Widget>[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Saving and analyzing — this may take a few seconds.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        loading ? null : () => context.go(AppRoutes.tenant),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyDropdown extends StatelessWidget {
  const _PropertyDropdown({
    required this.properties,
    required this.selected,
    required this.onChanged,
  });

  final AsyncValue<List<Property>> properties;
  final Property? selected;
  final ValueChanged<Property?> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Property',
          style: text.labelLarge?.copyWith(
            color: AppColors.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        properties.when(
          loading: () => _ShellField(
            child: Row(
              children: const <Widget>[
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading properties…'),
              ],
            ),
          ),
          error: (Object e, _) => const _ShellField(
            child: Text(
              'Could not load properties.',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          data: (List<Property> list) {
            if (list.isEmpty) {
              return const _ShellField(
                child: Text(
                  'No properties available yet. Ask your landlord to add one.',
                ),
              );
            }
            return DropdownButtonFormField<Property>(
              value: selected,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.apartment_rounded,
                  color: AppColors.mutedText,
                ),
                hintText: 'Choose a property',
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              validator: (Property? v) =>
                  v == null ? 'Please choose a property' : null,
              items: list
                  .map(
                    (Property p) => DropdownMenuItem<Property>(
                      value: p,
                      child: Text(
                        '${p.name} · ${p.streetLine}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onChanged,
            );
          },
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.selected, required this.onChanged});

  final RequestCategory? selected;
  final ValueChanged<RequestCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Category',
          style: text.labelLarge?.copyWith(
            color: AppColors.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<RequestCategory>(
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.category_outlined,
              color: AppColors.mutedText,
            ),
            hintText: 'Choose a category',
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          validator: (RequestCategory? v) =>
              v == null ? 'Please choose a category' : null,
          items: RequestCategory.values
              .map(
                (RequestCategory c) => DropdownMenuItem<RequestCategory>(
                  value: c,
                  child: Row(
                    children: <Widget>[
                      Icon(c.icon, size: 18, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Text(c.displayName),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _UrgencyDropdown extends StatelessWidget {
  const _UrgencyDropdown({required this.selected, required this.onChanged});

  final RequestUrgency selected;
  final ValueChanged<RequestUrgency> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Urgency',
          style: text.labelLarge?.copyWith(
            color: AppColors.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<RequestUrgency>(
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.priority_high_rounded,
              color: AppColors.mutedText,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: RequestUrgency.values
              .map(
                (RequestUrgency u) => DropdownMenuItem<RequestUrgency>(
                  value: u,
                  child: Text(u.displayName),
                ),
              )
              .toList(growable: false),
          onChanged: (RequestUrgency? v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Description',
          style: text.labelLarge?.copyWith(
            color: AppColors.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'When did it start? Where exactly is the issue?',
          ),
          validator: (String? v) =>
              Validators.required(v, field: 'Description'),
        ),
      ],
    );
  }
}

class _ShellField extends StatelessWidget {
  const _ShellField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
