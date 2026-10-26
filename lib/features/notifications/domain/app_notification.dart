import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification stored in `notifications/{notificationId}`.
///
/// These docs are written by Cloud Functions (using the admin SDK) when
/// significant events happen on a maintenance request. Clients only ever
/// read their own notifications and toggle [read] — never create.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.read,
    this.requestId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? requestId;
  final bool read;
  final DateTime? createdAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      requestId: requestId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  static AppNotification fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return AppNotification(
      id: snap.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      requestId: data['requestId'] as String?,
      read: (data['read'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
