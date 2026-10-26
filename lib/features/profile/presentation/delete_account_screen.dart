import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';

/// Two-step destructive flow: type-to-confirm, then call the
/// `deleteAccount` Cloud Function which cancels Stripe, wipes per-user
/// subcollections, deletes the profile doc, and deletes the Firebase Auth
/// user.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('deleteAccount')
          .call<Object?>(<String, Object?>{});

      // Sign out locally so the auth listener tears down all live streams
      // before the Auth user is gone.
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      context.go(AppRoutes.login);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Could not delete your account. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete your account. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppUser? user = ref.watch(appUserProvider).valueOrNull;
    final String confirmPhrase = (user?.email ?? 'delete').toLowerCase();
    final bool match =
        _confirmCtrl.text.trim().toLowerCase() == confirmPhrase;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This permanently deletes your profile, FCM tokens, '
                        'and active subscription. Maintenance requests you '
                        'authored will be retained for the other parties.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Type your email to confirm',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmCtrl,
                onChanged: (_) => setState(() {}),
                enabled: !_busy,
                decoration: InputDecoration(
                  hintText: confirmPhrase,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _busy || !match ? null : _delete,
                icon: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete account permanently'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => context.go(AppRoutes.settings),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
