import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import '../domain/user_role.dart';
import 'widgets/role_picker.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  UserRole? _role;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _role == null) {
      if (_role == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a role to continue.')),
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text,
          role: _role!,
        );
    final AsyncValue<void> state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      final String message = state.error is AuthException
          ? (state.error! as AuthException).message
          : 'Something went wrong.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
    // On success the router will redirect us to the appropriate dashboard.
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandHeader(
                    title: 'Create your account',
                    subtitle:
                        'Tell us a bit about you so we can tailor the experience.',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'I am a…',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 12),
                  RolePicker(
                    selected: _role,
                    onChanged: (UserRole r) => setState(() => _role = r),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: _nameCtrl,
                    label: 'Full name',
                    hintText: 'Jane Doe',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (String? v) =>
                        Validators.required(v, field: 'Name'),
                    prefixIcon: Icons.person_outline_rounded,
                    autofillHints: const <String>[AutofillHints.name],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                    prefixIcon: Icons.alternate_email_rounded,
                    autofillHints: const <String>[AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hintText: 'At least 8 characters',
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.mutedText,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmCtrl,
                    label: 'Confirm password',
                    hintText: 'Re-enter your password',
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    validator: (String? v) =>
                        Validators.confirmPassword(v, _passwordCtrl.text),
                    prefixIcon: Icons.lock_outline_rounded,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create account',
                    loading: loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedText,
                            ),
                      ),
                      TextButton(
                        onPressed: loading ? null : () => context.go('/login'),
                        child: const Text('Sign in'),
                      ),
                    ],
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
