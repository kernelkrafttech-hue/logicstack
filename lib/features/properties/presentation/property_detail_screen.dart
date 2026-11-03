import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/property_providers.dart';
import '../domain/property.dart';

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Property?> async = ref.watch(
      propertyByIdProvider(propertyId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.properties),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => _Message(
            icon: Icons.error_outline_rounded,
            tone: AppColors.error,
            title: 'Could not load property',
            body: '$error',
          ),
          data: (Property? property) {
            if (property == null) {
              return const _Message(
                icon: Icons.search_off_rounded,
                tone: AppColors.mutedText,
                title: 'Property not found',
                body: 'It may have been removed.',
              );
            }
            return _PropertyBody(property: property);
          },
        ),
      ),
    );
  }
}

class _PropertyBody extends StatelessWidget {
  const _PropertyBody({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                property.name,
                style: text.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                property.streetLine,
                style: text.bodyMedium?.copyWith(color: AppColors.white),
              ),
              Text(
                property.cityLine,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Address',
          style: text.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(label: 'Street', value: property.address),
        if (property.unit.isNotEmpty)
          _DetailRow(label: 'Unit', value: property.unit),
        _DetailRow(label: 'City', value: property.city),
        _DetailRow(label: 'State', value: property.state),
        _DetailRow(label: 'ZIP code', value: property.zipCode),
        const SizedBox(height: 24),
        Text(
          'Activity',
          style: text.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
          label: 'Added',
          value: _formatDate(property.createdAt),
        ),
        _DetailRow(
          label: 'Last updated',
          value: _formatDate(property.updatedAt),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMMd().add_jm().format(date.toLocal());
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: tone, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
