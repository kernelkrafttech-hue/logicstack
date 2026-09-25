import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/domain/user_role.dart';

/// Identifies the kind of event written to the request's `activity`
/// subcollection. Storage values are stable so future history queries can
/// filter without breaking on rename.
enum ActivityType {
  submitted(
    storageValue: 'submitted',
    icon: Icons.send_rounded,
  ),
  statusChanged(
    storageValue: 'status_changed',
    icon: Icons.swap_horiz_rounded,
  ),
  contractorAssigned(
    storageValue: 'contractor_assigned',
    icon: Icons.engineering_rounded,
  );

  const ActivityType({required this.storageValue, required this.icon});

  final String storageValue;
  final IconData icon;

  static ActivityType fromStorage(String? value) {
    for (final ActivityType t in ActivityType.values) {
      if (t.storageValue == value) return t;
    }
    return ActivityType.statusChanged;
  }
}

/// Lightweight value type used by repositories to attach actor info to an
/// activity event without dragging the full [AppUser] around.
class ActivityActor {
  const ActivityActor({
    required this.uid,
    required this.name,
    required this.role,
  });

  final String uid;
  final String name;
  final UserRole role;

  String get roleLabel => role.displayName.toLowerCase();
}

/// An event in the request's audit timeline. The `title` and `description`
/// fields are pre-rendered at write time so the timeline can render quickly
/// without joining against the user collection.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.requestId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String requestId;
  final ActivityType type;
  final String title;
  final String description;
  final String createdBy;
  final DateTime? createdAt;

  Map<String, Object?> toFirestoreCreate() {
    return <String, Object?>{
      'requestId': requestId,
      'type': type.storageValue,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static ActivityEvent fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return ActivityEvent(
      id: snap.id,
      requestId: (data['requestId'] as String?) ?? '',
      type: ActivityType.fromStorage(data['type'] as String?),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Convenience for the timeline UI — a hint at the visual weight of an event.
extension ActivityTone on ActivityType {
  Color get tone {
    switch (this) {
      case ActivityType.submitted:
        return AppColors.lightGray;
      case ActivityType.statusChanged:
        return const Color(0xFFE3EEFB);
      case ActivityType.contractorAssigned:
        return AppColors.greenSoft;
    }
  }

  Color get foreground {
    switch (this) {
      case ActivityType.submitted:
        return AppColors.navy;
      case ActivityType.statusChanged:
        return AppColors.info;
      case ActivityType.contractorAssigned:
        return AppColors.greenDark;
    }
  }
}
