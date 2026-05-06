import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Application-level user model backed by the `users/{uid}` Firestore document.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.storageValue,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static AppUser fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    final UserRole? role = UserRole.fromStorage(data['role'] as String?);
    if (role == null) {
      throw StateError('User document ${snap.id} has invalid role.');
    }
    return AppUser(
      uid: snap.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      role: role,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
