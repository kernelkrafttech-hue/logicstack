import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum StatTone { neutral, success, warning, danger }

/// Compact metric card used in the landlord dashboard overview grid.
///
/// Shows a tinted icon, a numeric [value], and a short [label]. When [onTap]
/// is provided the entire card behaves as a tap target.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatTone.neutral,
    this.loading = false,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatTone tone;
  final bool loading;
  final VoidCallback? onTap;

  ({Color background, Color foreground}) get _toneColors {
    switch (tone) {
      case StatTone.success:
        return (background: AppColors.greenSoft, foreground: AppColors.greenDark);
      case StatTone.warning:
        return (background: const Color(0xFFFFF4DB), foreground: AppColors.warning);
      case StatTone.danger:
        return (background: const Color(0xFFFCE7E7), foreground: AppColors.error);
      case StatTone.neutral:
        return (background: AppColors.lightGray, foreground: AppColors.navy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ({Color background, Color foreground}) tones = _toneColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: tones.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: tones.foreground),
              ),
              const SizedBox(height: 12),
              if (loading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
                  ),
                )
              else
                Text(
                  value,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: text.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
