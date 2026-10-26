import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/contractor.dart';

class ContractorCard extends StatelessWidget {
  const ContractorCard({
    required this.contractor,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final Contractor contractor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(contractor.trade.icon, color: AppColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      contractor.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contractor.companyName.isEmpty
                          ? contractor.trade.displayName
                          : '${contractor.companyName} · ${contractor.trade.displayName}',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contractor.email.isNotEmpty)
                      Text(
                        contractor.email,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.bodyText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
