import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/contractor.dart';

class ContractorException implements Exception {
  ContractorException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads and writes the `contractors/{contractorId}` collection.
class ContractorRepository {
  ContractorRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.contractorsCollection);

  Stream<List<Contractor>> watchContractorsForLandlord(String landlordId) {
    return _collection
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(Contractor.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<Contractor?> watchContractor(String id) {
    return _collection.doc(id).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snap) {
        if (!snap.exists) return null;
        return Contractor.fromFirestore(snap);
      },
    );
  }

  Future<Contractor> createContractor({
    required String landlordId,
    required String name,
    required String companyName,
    required String phone,
    required String email,
    required ContractorTrade trade,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _collection.doc();
      final Contractor contractor = Contractor(
        id: ref.id,
        landlordId: landlordId,
        name: name.trim(),
        companyName: companyName.trim(),
        phone: phone.trim(),
        email: email.trim().toLowerCase(),
        trade: trade,
      );
      await ref.set(contractor.toFirestoreCreate());
      return contractor;
    } on FirebaseException catch (e) {
      throw ContractorException(_messageForCode(e.code));
    }
  }

  Future<void> updateContractor(Contractor contractor) async {
    try {
      await _collection.doc(contractor.id).update(
            contractor
                .copyWith(
                  email: contractor.email.toLowerCase(),
                )
                .toFirestoreUpdate(),
          );
    } on FirebaseException catch (e) {
      throw ContractorException(_messageForCode(e.code));
    }
  }

  Future<void> deleteContractor(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ContractorException(_messageForCode(e.code));
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
