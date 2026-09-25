import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_providers.dart';

/// Tappable banner shown above dashboard content when the signed-in user
/// hasn't verified their email yet. Hidden once Firebase Auth flips
/// `emailVerified` to true.
class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink();
    }
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.verifyEmail),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Verify your email',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Tap to resend the verification link to ${user.email ?? 'your inbox'}.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
