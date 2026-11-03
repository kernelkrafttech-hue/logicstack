import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailCtrl.text);
    if (!mounted) return;
    final AsyncValue<void> state = ref.read(authControllerProvider);
    if (state.hasError) {
      final Object? error = state.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AuthException
                ? error.message
                : 'Could not send reset email.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const BrandHeader(
                  title: 'Reset your password',
                  subtitle:
                      'Enter the email on your account and we\'ll send a '
                      'reset link.',
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: Validators.email,
                  onSubmitted: (_) => _submit(),
                  autofillHints: const <String>[AutofillHints.email],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Send reset link',
                  loading: loading,
                  onPressed: _submit,
                  icon: Icons.send_rounded,
                ),
                if (_sent) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green),
                    ),
                    child: Text(
                      'Check your inbox — the reset link should arrive in '
                      'a couple of minutes. Don\'t forget to check spam.',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
