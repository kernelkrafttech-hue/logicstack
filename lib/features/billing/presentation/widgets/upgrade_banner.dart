import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/plan.dart';

/// Compact upsell banner used wherever a feature is gated by plan. Tapping
/// it opens the subscription screen.
class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({
    required this.message,
    this.suggestedPlan,
    super.key,
  });

  final String message;
  final Plan? suggestedPlan;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Plan? plan = suggestedPlan;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.subscription),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.greenDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      plan == null
                          ? 'Upgrade your plan'
                          : 'Upgrade to ${plan.displayName}',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.greenDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
