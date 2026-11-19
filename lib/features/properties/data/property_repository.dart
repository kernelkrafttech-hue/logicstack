import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/property.dart';

class PropertyException implements Exception {
  PropertyException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads and writes the `properties/{propertyId}` collection.
///
/// The repository never assumes a caller's role; access control is enforced by
/// Firestore rules. UI code passes in the current user's uid when scoping a
/// query, which matches what the security rules will accept.
class PropertyRepository {
  PropertyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.propertiesCollection);

  /// Live list of properties owned by [ownerId], newest first.
  Stream<List<Property>> watchPropertiesForOwner(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(Property.fromFirestore)
              .toList(growable: false),
        );
  }

  /// Live list of every property in the system, newest first.
  ///
  /// Used by the tenant submission flow until proper tenant↔property
  /// invitations land. Access is gated by Firestore rules.
  Stream<List<Property>> watchAllProperties() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(Property.fromFirestore)
              .toList(growable: false),
        );
  }

  /// Live single property. Emits `null` when the document doesn't exist.
  Stream<Property?> watchProperty(String id) {
    return _collection.doc(id).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snap) {
        if (!snap.exists) return null;
        return Property.fromFirestore(snap);
      },
    );
  }

  Future<Property> fetchProperty(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snap =
        await _collection.doc(id).get();
    if (!snap.exists) {
      throw PropertyException('Property not found.');
    }
    return Property.fromFirestore(snap);
  }

  /// Creates a new property and returns the persisted model with its id and
  /// the locally-known timestamps left null (the server fills those in).
  Future<Property> createProperty({
    required String ownerId,
    required String name,
    required String address,
    required String unit,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _collection.doc();
      final Property property = Property(
        id: ref.id,
        ownerId: ownerId,
        name: name.trim(),
        address: address.trim(),
        unit: unit.trim(),
        city: city.trim(),
        state: state.trim().toUpperCase(),
        zipCode: zipCode.trim(),
      );
      await ref.set(property.toFirestoreCreate());
      return property;
    } on FirebaseException catch (e) {
      throw PropertyException(_messageForCode(e.code));
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return "You don't have permission to perform that action.";
      case 'unavailable':
        return 'Network error. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
