import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Initial loading screen shown while auth state and the user profile resolve.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.green, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.handyman_rounded,
                color: AppColors.green,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: text.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.tagline,
              style: text.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
