import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_prefs.dart';
import '../../../core/theme/app_colors.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

const List<_OnboardingPageData> _pages = <_OnboardingPageData>[
  _OnboardingPageData(
    icon: Icons.handyman_rounded,
    title: 'Maintenance, coordinated',
    body:
        'MaintenanceOS is the shared inbox for landlords, tenants, and contractors. '
        'Every request lands in one place, with a clear audit trail.',
  ),
  _OnboardingPageData(
    icon: Icons.auto_awesome_rounded,
    title: 'AI-assisted triage',
    body:
        'Tenants describe the problem in their own words. We route the right '
        'trade, suggest urgency, and draft a contractor message — automatically.',
  ),
  _OnboardingPageData(
    icon: Icons.notifications_active_rounded,
    title: 'Stay in the loop',
    body:
        'Push notifications and the activity timeline keep everyone in sync as '
        'jobs move from submitted to scheduled to done.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final OnboardingPrefs? prefs =
        ref.read(onboardingPrefsProvider).valueOrNull;
    await prefs?.markSeen();
    ref.read(onboardingSeenProvider.notifier).state = true;
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isLast = _index == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.white),
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (int i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (BuildContext context, int i) =>
                    _OnboardingPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: i == _index ? 22 : 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.green
                                : AppColors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(isLast ? 'Get started' : 'Next'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your role on the next screen — landlord, tenant, '
                    'or contractor — and we\'ll tailor the experience.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: AppColors.navyDark,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 44, color: AppColors.green),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
