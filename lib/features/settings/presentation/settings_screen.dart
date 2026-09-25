import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';

/// Single hub for everything that doesn't fit on a dashboard:
///   - Profile editing
///   - Theme mode
///   - Notifications (link to in-app list — system permission lives in OS
///     settings)
///   - Subscription
///   - Support / Terms / Privacy / Delete account / Sign out
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You\'ll need to enter your credentials again to come back.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(appUserProvider).valueOrNull;
    final ThemeMode mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (user == null) {
              context.go(AppRoutes.login);
              return;
            }
            context.go(AppRoutes.dashboardFor(user.role));
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: <Widget>[
            if (user != null) _AccountSummary(user: user),
            const SizedBox(height: 16),
            _SectionHeader('Account'),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              caption: 'Name, phone, company, photo',
              onTap: () => context.go(AppRoutes.profile),
            ),
            _SettingsTile(
              icon: Icons.workspace_premium_rounded,
              label: 'Subscription',
              caption: 'Plan, billing, cancel',
              onTap: () => context.go(AppRoutes.subscription),
            ),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              caption: 'See your in-app notifications',
              onTap: () => context.go(AppRoutes.notifications),
            ),
            const SizedBox(height: 16),
            _SectionHeader('Appearance'),
            _SettingsTile(
              icon: mode.icon,
              label: mode.label,
              caption: 'Tap to cycle: system → light → dark',
              onTap: () =>
                  ref.read(themeModeProvider.notifier).state = mode.next,
              trailing: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(height: 16),
            _SectionHeader('Help and policies'),
            _SettingsTile(
              icon: Icons.support_agent_rounded,
              label: 'Contact support',
              onTap: () => context.go(AppRoutes.support),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () => context.go(AppRoutes.terms),
            ),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy Policy',
              onTap: () => context.go(AppRoutes.privacy),
            ),
            const SizedBox(height: 16),
            _SectionHeader('Session'),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              onTap: () => _confirmSignOut(context, ref),
            ),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete account',
              caption: 'Permanently remove your account and data',
              destructive: true,
              onTap: () => context.go(AppRoutes.deleteAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.lightGray,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!) as ImageProvider<Object>
                : null,
            child: user.photoUrl == null
                ? Text(
                    user.initials,
                    style: text.titleMedium?.copyWith(color: AppColors.navy),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.displayName.isEmpty ? 'Add your name' : user.displayName,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.email,
                  style: text.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
                Text(
                  user.role.displayName,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? caption;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color fg =
        destructive ? AppColors.error : AppColors.bodyText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: destructive
                      ? const Color(0xFFFCE7E7)
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: destructive ? AppColors.error : AppColors.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    if (caption != null && caption!.isNotEmpty)
                      Text(
                        caption!,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
