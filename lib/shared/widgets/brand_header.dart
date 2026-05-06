import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Compact brand mark used at the top of auth screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.handyman_rounded,
            color: AppColors.green,
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ],
    );
  }
}
