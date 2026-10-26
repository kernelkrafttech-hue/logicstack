import 'dart:io';

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
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../application/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _companyCtrl = TextEditingController();

  XFile? _newPhoto;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  void _hydrate(AppUser user) {
    if (_hydrated) return;
    _nameCtrl.text = user.displayName;
    _phoneCtrl.text = user.phone;
    _companyCtrl.text = user.companyName;
    _hydrated = true;
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) setState(() => _newPhoto = picked);
    } catch (_) {
      _showError('Could not open the photo picker.');
    }
  }

  Future<void> _save(AppUser user) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final bool ok = await ref.read(profileControllerProvider.notifier).save(
          user: user,
          displayName: _nameCtrl.text,
          phone: _phoneCtrl.text,
          companyName: _companyCtrl.text,
          photoFile: _newPhoto != null ? File(_newPhoto!.path) : null,
        );

    if (!mounted) return;
    if (ok) {
      setState(() => _newPhoto = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
      return;
    }
    final AsyncValue<void> state = ref.read(profileControllerProvider);
    final Object? error = state.error;
    _showError(
      error is AuthException ? error.message : 'Could not save your profile.',
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
    final AsyncValue<AppUser?> async = ref.watch(appUserProvider);
    final bool busy = ref.watch(profileControllerProvider).isLoading;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) =>
              Center(child: Text('$error')),
          data: (AppUser? user) {
            if (user == null) return const SizedBox.shrink();
            _hydrate(user);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: _AvatarPicker(
                        user: user,
                        newPhoto: _newPhoto,
                        onPick: busy ? null : _pickPhoto,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        user.email,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                      controller: _phoneCtrl,
                      label: 'Phone',
                      hintText: '(555) 123-4567',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _companyCtrl,
                      label: 'Company (optional)',
                      hintText: 'Doe Property Management',
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Save changes',
                      loading: busy,
                      onPressed: () => _save(user),
                      icon: Icons.check_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.user,
    required this.newPhoto,
    required this.onPick,
  });

  final AppUser user;
  final XFile? newPhoto;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? backing = newPhoto != null
        ? FileImage(File(newPhoto!.path))
        : (user.photoUrl != null
            ? NetworkImage(user.photoUrl!) as ImageProvider<Object>?
            : null);

    return GestureDetector(
      onTap: onPick,
      child: Stack(
        children: <Widget>[
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.lightGray,
            backgroundImage: backing,
            child: backing == null
                ? Text(
                    user.initials,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.navy),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
