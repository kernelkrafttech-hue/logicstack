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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    final AsyncValue<void> state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      _showError(state.error);
    }
    // On success the router redirect will move us to the dashboard.
  }

  Future<void> _resetPassword() async {
    final String email = _emailCtrl.text.trim();
    if (Validators.email(email) != null) {
      _showError('Enter your email above to receive a reset link.');
      return;
    }
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    final AsyncValue<void> state = ref.read(authControllerProvider);
    if (state.hasError) {
      _showError(state.error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    }
  }

  void _showError(Object? error) {
    final String message =
        error is AuthException ? error.message : 'Something went wrong.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandHeader(
                    title: 'Welcome back',
                    subtitle: 'Sign in to manage your maintenance workflow.',
                  ),
                  const SizedBox(height: 32),
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
                    hintText: 'Your password',
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const <String>[AutofillHints.password],
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.mutedText,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Sign in',
                    loading: loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedText,
                            ),
                      ),
                      TextButton(
                        onPressed: loading ? null : () => context.go('/signup'),
                        child: const Text('Create one'),
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
