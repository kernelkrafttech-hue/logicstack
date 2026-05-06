import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/user_role.dart';

/// A free-form message attached to a maintenance request, visible to every
/// party who can read the request itself (tenant, landlord, assigned
/// contractor).
///
/// Backed by `maintenanceRequests/{requestId}/comments/{commentId}`.
class RequestComment {
  const RequestComment({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String requestId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String text;
  final DateTime? createdAt;

  Map<String, Object?> toFirestoreCreate() {
    return <String, Object?>{
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.storageValue,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static RequestComment fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    final UserRole role =
        UserRole.fromStorage(data['senderRole'] as String?) ?? UserRole.tenant;
    return RequestComment(
      id: snap.id,
      requestId: (data['requestId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      senderRole: role,
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
