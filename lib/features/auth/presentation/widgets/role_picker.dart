import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/user_role.dart';

class RolePicker extends StatelessWidget {
  const RolePicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < UserRole.values.length; i++) ...<Widget>[
          _RoleCard(
            role: UserRole.values[i],
            selected: UserRole.values[i] == selected,
            onTap: () => onChanged(UserRole.values[i]),
          ),
          if (i != UserRole.values.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (role) {
      case UserRole.landlord:
        return Icons.apartment_rounded;
      case UserRole.tenant:
        return Icons.home_rounded;
      case UserRole.contractor:
        return Icons.build_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenSoft : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.green : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
                  color: selected ? AppColors.white : AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role.displayName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.green : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
