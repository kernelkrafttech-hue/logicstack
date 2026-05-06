import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Lifecycle states a maintenance request moves through.
///
/// Phase 3 only writes [submitted]; later phases (contractor dispatch, AI
/// triage) will transition through the rest. The enum is defined now so the
/// model and rules don't need to change when those features land.
enum RequestStatus {
  submitted(storageValue: 'submitted', displayName: 'Submitted'),
  inProgress(storageValue: 'in_progress', displayName: 'In progress'),
  completed(storageValue: 'completed', displayName: 'Completed'),
  cancelled(storageValue: 'cancelled', displayName: 'Cancelled');

  const RequestStatus({
    required this.storageValue,
    required this.displayName,
  });

  final String storageValue;
  final String displayName;

  static RequestStatus fromStorage(String? value) {
    for (final RequestStatus s in RequestStatus.values) {
      if (s.storageValue == value) return s;
    }
    return RequestStatus.submitted;
  }
}

enum RequestUrgency {
  low(storageValue: 'low', displayName: 'Low'),
  medium(storageValue: 'medium', displayName: 'Medium'),
  high(storageValue: 'high', displayName: 'High'),
  emergency(storageValue: 'emergency', displayName: 'Emergency');

  const RequestUrgency({
    required this.storageValue,
    required this.displayName,
  });

  final String storageValue;
  final String displayName;

  /// Background tint used by the urgency badge.
  Color get tone {
    switch (this) {
      case RequestUrgency.low:
        return AppColors.lightGray;
      case RequestUrgency.medium:
        return AppColors.greenSoft;
      case RequestUrgency.high:
        return const Color(0xFFFFF4DB);
      case RequestUrgency.emergency:
        return const Color(0xFFFCE7E7);
    }
  }

  Color get foreground {
    switch (this) {
      case RequestUrgency.low:
        return AppColors.bodyText;
      case RequestUrgency.medium:
        return AppColors.greenDark;
      case RequestUrgency.high:
        return AppColors.warning;
      case RequestUrgency.emergency:
        return AppColors.error;
    }
  }

  static RequestUrgency fromStorage(String? value) {
    for (final RequestUrgency u in RequestUrgency.values) {
      if (u.storageValue == value) return u;
    }
    return RequestUrgency.medium;
  }
}

enum RequestCategory {
  plumbing(
    storageValue: 'plumbing',
    displayName: 'Plumbing',
    icon: Icons.plumbing_rounded,
  ),
  electrical(
    storageValue: 'electrical',
    displayName: 'Electrical',
    icon: Icons.electrical_services_rounded,
  ),
  hvac(
    storageValue: 'hvac',
    displayName: 'HVAC',
    icon: Icons.hvac_rounded,
  ),
  appliance(
    storageValue: 'appliance',
    displayName: 'Appliance',
    icon: Icons.kitchen_rounded,
  ),
  pest(
    storageValue: 'pest',
    displayName: 'Pest control',
    icon: Icons.pest_control_rounded,
  ),
  structural(
    storageValue: 'structural',
    displayName: 'Structural',
    icon: Icons.foundation_rounded,
  ),
  other(
    storageValue: 'other',
    displayName: 'Other',
    icon: Icons.handyman_rounded,
  );

  const RequestCategory({
    required this.storageValue,
    required this.displayName,
    required this.icon,
  });

  final String storageValue;
  final String displayName;
  final IconData icon;

  static RequestCategory fromStorage(String? value) {
    for (final RequestCategory c in RequestCategory.values) {
      if (c.storageValue == value) return c;
    }
    return RequestCategory.other;
  }
}

/// A maintenance request submitted by a tenant against a property.
///
/// Backed by `maintenanceRequests/{requestId}`. The model owns its enum
/// translation so repositories stay free of magic strings.
class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.propertyId,
    required this.landlordId,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.status,
    required this.photoUrls,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String landlordId;
  final String tenantId;
  final String title;
  final String description;
  final RequestCategory category;
  final RequestUrgency urgency;
  final RequestStatus status;
  final List<String> photoUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toFirestoreCreate() {
    return <String, Object?>{
      'propertyId': propertyId,
      'landlordId': landlordId,
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'category': category.storageValue,
      'urgency': urgency.storageValue,
      'status': status.storageValue,
      'photoUrls': photoUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static MaintenanceRequest fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    final List<String> photos = (data['photoUrls'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    return MaintenanceRequest(
      id: snap.id,
      propertyId: (data['propertyId'] as String?) ?? '',
      landlordId: (data['landlordId'] as String?) ?? '',
      tenantId: (data['tenantId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: RequestCategory.fromStorage(data['category'] as String?),
      urgency: RequestUrgency.fromStorage(data['urgency'] as String?),
      status: RequestStatus.fromStorage(data['status'] as String?),
      photoUrls: photos,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
