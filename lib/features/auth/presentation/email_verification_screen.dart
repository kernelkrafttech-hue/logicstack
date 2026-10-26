import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _resending = false;
  bool _checking = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    try {
      final bool verified = await ref
          .read(authRepositoryProvider)
          .reloadAndCheckEmailVerified();
      if (!mounted) return;
      if (verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified — thanks!')),
        );
        final AppUser? user = ref.read(appUserProvider).valueOrNull;
        if (user != null) {
          context.go(AppRoutes.dashboardFor(user.role));
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still not verified — try again.')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            final AppUser? appUser = ref.read(appUserProvider).valueOrNull;
            if (appUser != null) {
              context.go(AppRoutes.dashboardFor(appUser.role));
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              Container(
                height: 96,
                width: 96,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.greenDark,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to ${user?.email ?? 'your inbox'}. '
                'Click the link in that email, then come back and tap '
                'I\'ve verified.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: "I've verified",
                loading: _checking,
                onPressed: _refreshStatus,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _resending ? null : _resend,
                icon: _resending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Resend verification email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
