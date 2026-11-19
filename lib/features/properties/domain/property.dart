import 'package:cloud_firestore/cloud_firestore.dart';

/// A rental property owned by a landlord.
///
/// Backed by `properties/{propertyId}`. The Firestore document stores the
/// owner uid so security rules can scope queries; [id] is the document id and
/// is not duplicated in the document body.
class Property {
  const Property({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.unit,
    required this.city,
    required this.state,
    required this.zipCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String address;

  /// Optional apartment / suite number. Empty string when not applicable.
  final String unit;

  final String city;
  final String state;
  final String zipCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Single-line summary suitable for list rows.
  String get streetLine {
    if (unit.isEmpty) return address;
    return '$address, Unit $unit';
  }

  /// Second-line summary suitable for list rows.
  String get cityLine => '$city, $state $zipCode';

  Property copyWith({
    String? name,
    String? address,
    String? unit,
    String? city,
    String? state,
    String? zipCode,
    DateTime? updatedAt,
  }) {
    return Property(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      unit: unit ?? this.unit,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toFirestoreCreate() {
    return <String, Object?>{
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'unit': unit,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Property fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    return Property(
      id: snap.id,
      ownerId: (data['ownerId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      unit: (data['unit'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      state: (data['state'] as String?) ?? '',
      zipCode: (data['zipCode'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
