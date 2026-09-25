import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Trades a contractor can declare. The values overlap with
/// [RequestCategory] but stay independent so Phase 6 doesn't have to drag
/// the request enum into contractor concerns.
enum ContractorTrade {
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
    displayName: 'Appliance repair',
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
  general(
    storageValue: 'general',
    displayName: 'General contractor',
    icon: Icons.handyman_rounded,
  );

  const ContractorTrade({
    required this.storageValue,
    required this.displayName,
    required this.icon,
  });

  final String storageValue;
  final String displayName;
  final IconData icon;

  static ContractorTrade fromStorage(String? value) {
    for (final ContractorTrade t in ContractorTrade.values) {
      if (t.storageValue == value) return t;
    }
    return ContractorTrade.general;
  }
}

/// A contractor in a landlord's roster.
///
/// Backed by `contractors/{contractorId}`. Email is the join key used to
/// surface jobs to the contractor's own dashboard once they sign in with the
/// same address.
class Contractor {
  const Contractor({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.trade,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String landlordId;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final ContractorTrade trade;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayLine =>
      companyName.isEmpty ? name : '$name · $companyName';

  Contractor copyWith({
    String? name,
    String? companyName,
    String? phone,
    String? email,
    ContractorTrade? trade,
    DateTime? updatedAt,
  }) {
    return Contractor(
      id: id,
      landlordId: landlordId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      trade: trade ?? this.trade,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toFirestoreCreate() {
    return <String, Object?>{
      'landlordId': landlordId,
      'name': name,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'trade': trade.storageValue,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> toFirestoreUpdate() {
    return <String, Object?>{
      'name': name,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'trade': trade.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Contractor fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return Contractor(
      id: snap.id,
      landlordId: (data['landlordId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      trade: ContractorTrade.fromStorage(data['trade'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
