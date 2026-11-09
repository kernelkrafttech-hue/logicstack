import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Lifecycle states a maintenance request moves through.
///
/// Phase 3 only writes [submitted]; Phase 4 lets a landlord transition through
/// [reviewed], [sentToContractor], [scheduled], [inProgress], [completed],
/// [closed], or [cancelled].
enum RequestStatus {
  submitted(storageValue: 'submitted', displayName: 'Submitted'),
  reviewed(storageValue: 'reviewed', displayName: 'Reviewed'),
  sentToContractor(
    storageValue: 'sent_to_contractor',
    displayName: 'Sent to contractor',
  ),
  accepted(storageValue: 'accepted', displayName: 'Accepted'),
  scheduled(storageValue: 'scheduled', displayName: 'Scheduled'),
  inProgress(storageValue: 'in_progress', displayName: 'In progress'),
  completed(storageValue: 'completed', displayName: 'Completed'),
  closed(storageValue: 'closed', displayName: 'Closed'),
  cancelled(storageValue: 'cancelled', displayName: 'Cancelled');

  const RequestStatus({
    required this.storageValue,
    required this.displayName,
  });

  final String storageValue;
  final String displayName;

  /// Whether the request still needs landlord/contractor attention.
  bool get isOpen {
    switch (this) {
      case RequestStatus.submitted:
      case RequestStatus.reviewed:
      case RequestStatus.sentToContractor:
      case RequestStatus.accepted:
      case RequestStatus.scheduled:
      case RequestStatus.inProgress:
        return true;
      case RequestStatus.completed:
      case RequestStatus.closed:
      case RequestStatus.cancelled:
        return false;
    }
  }

  /// Background tint for the status chip.
  Color get tone {
    switch (this) {
      case RequestStatus.submitted:
        return AppColors.lightGray;
      case RequestStatus.reviewed:
        return const Color(0xFFE3EEFB);
      case RequestStatus.sentToContractor:
        return const Color(0xFFEDE7F6);
      case RequestStatus.accepted:
        return AppColors.greenSoft;
      case RequestStatus.scheduled:
        return const Color(0xFFE3EEFB);
      case RequestStatus.inProgress:
        return const Color(0xFFFFF4DB);
      case RequestStatus.completed:
        return AppColors.greenSoft;
      case RequestStatus.closed:
        return AppColors.lightGray;
      case RequestStatus.cancelled:
        return const Color(0xFFFCE7E7);
    }
  }

  Color get foreground {
    switch (this) {
      case RequestStatus.submitted:
        return AppColors.bodyText;
      case RequestStatus.reviewed:
        return AppColors.info;
      case RequestStatus.sentToContractor:
        return const Color(0xFF6B46C1);
      case RequestStatus.accepted:
        return AppColors.greenDark;
      case RequestStatus.scheduled:
        return AppColors.info;
      case RequestStatus.inProgress:
        return AppColors.warning;
      case RequestStatus.completed:
        return AppColors.greenDark;
      case RequestStatus.closed:
        return AppColors.mutedText;
      case RequestStatus.cancelled:
        return AppColors.error;
    }
  }

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

  /// Like [fromStorage] but returns `null` for unknown values, so the AI
  /// suggestion can fall back to plain text rendering.
  static RequestUrgency? fromStorageOrNull(String? value) {
    if (value == null) return null;
    for (final RequestUrgency u in RequestUrgency.values) {
      if (u.storageValue == value) return u;
    }
    return null;
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

/// Result of running a request through the `analyzeMaintenanceRequest`
/// Cloud Function. Used by the AI service and the repository's update helper.
class AiAnalysis {
  const AiAnalysis({
    required this.aiSummary,
    required this.likelyTrade,
    required this.urgencySuggestion,
    required this.contractorMessage,
  });

  final String aiSummary;
  final String likelyTrade;
  final String urgencySuggestion;
  final String contractorMessage;

  /// Maps [urgencySuggestion] back onto a [RequestUrgency] when it parses
  /// cleanly, so the UI can render an [UrgencyBadge].
  RequestUrgency? get suggestedUrgencyEnum =>
      RequestUrgency.fromStorageOrNull(urgencySuggestion);
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
    this.aiSummary,
    this.likelyTrade,
    this.urgencySuggestion,
    this.contractorMessage,
    this.aiAnalyzedAt,
    this.contractorId,
    this.contractorName,
    this.contractorTrade,
    this.contractorEmail,
    this.assignedAt,
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

  // AI fields, populated asynchronously by the analyzeMaintenanceRequest
  // Cloud Function after the doc is created.
  final String? aiSummary;
  final String? likelyTrade;
  final String? urgencySuggestion;
  final String? contractorMessage;
  final DateTime? aiAnalyzedAt;

  // Contractor assignment fields. Populated when a landlord assigns a
  // contractor on the detail screen. Email is denormalized so security
  // rules can match the signed-in contractor without an extra `get()`.
  final String? contractorId;
  final String? contractorName;
  final String? contractorTrade;
  final String? contractorEmail;
  final DateTime? assignedAt;

  bool get hasContractorAssigned =>
      contractorId != null && contractorId!.isNotEmpty;

  bool get hasAiAnalysis => aiAnalyzedAt != null;

  /// The AI's urgency suggestion mapped back to a [RequestUrgency], if it
  /// matches one of the known storage values.
  RequestUrgency? get aiUrgencyEnum =>
      RequestUrgency.fromStorageOrNull(urgencySuggestion);

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
      aiSummary: data['aiSummary'] as String?,
      likelyTrade: data['likelyTrade'] as String?,
      urgencySuggestion: data['urgencySuggestion'] as String?,
      contractorMessage: data['contractorMessage'] as String?,
      aiAnalyzedAt: (data['aiAnalyzedAt'] as Timestamp?)?.toDate(),
      contractorId: data['contractorId'] as String?,
      contractorName: data['contractorName'] as String?,
      contractorTrade: data['contractorTrade'] as String?,
      contractorEmail: data['contractorEmail'] as String?,
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
    );
  }
}
