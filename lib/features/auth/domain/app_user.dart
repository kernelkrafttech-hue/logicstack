import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Application-level user model backed by the `users/{uid}` Firestore document.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone = '',
    this.companyName = '',
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  /// Optional contact phone, surfaced in the profile screen and used by
  /// landlords + contractors to reach each other.
  final String phone;

  /// Optional company name (mostly relevant for contractors and
  /// property-management landlords).
  final String companyName;

  /// Cloud Storage download URL of the user's avatar, or `null` when they
  /// haven't uploaded one yet.
  final String? photoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Initials shown when no [photoUrl] is set.
  String get initials {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return email.isEmpty ? '?' : email.substring(0, 1).toUpperCase();
    }
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    String? phone,
    String? companyName,
    String? photoUrl,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      photoUrl: photoUrl ?? this.photoUrl,
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
      'phone': phone,
      'companyName': companyName,
      'photoUrl': photoUrl,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Profile-only field set for the update endpoint. Excludes immutable
  /// fields (`uid`, `email`, `role`) so misuse can't change a user's role.
  Map<String, Object?> toProfileUpdate() {
    return <String, Object?>{
      'displayName': displayName,
      'phone': phone,
      'companyName': companyName,
      'photoUrl': photoUrl,
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
      phone: (data['phone'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
