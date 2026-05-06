import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/maintenance_request.dart';

class RequestException implements Exception {
  RequestException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads and writes the `maintenanceRequests/{requestId}` collection and the
/// matching photo objects in Cloud Storage.
///
/// All access control lives in Firestore + Storage rules; this layer just
/// provides typed helpers and turns Firebase exceptions into user-friendly
/// messages.
class RequestRepository {
  RequestRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.maintenanceRequestsCollection);

  Stream<List<MaintenanceRequest>> watchRequestsForTenant(String tenantId) {
    return _collection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(MaintenanceRequest.fromFirestore)
              .toList(growable: false),
        );
  }

  /// Live list of every request landed against properties owned by [landlordId].
  Stream<List<MaintenanceRequest>> watchRequestsForLandlord(String landlordId) {
    return _collection
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(MaintenanceRequest.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<MaintenanceRequest?> watchRequest(String id) {
    return _collection.doc(id).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snap) {
        if (!snap.exists) return null;
        return MaintenanceRequest.fromFirestore(snap);
      },
    );
  }

  /// Generates a fresh request id without writing anything yet.
  ///
  /// We need the id up front so photo uploads can use it as their Storage
  /// path before the Firestore document is created.
  String newRequestId() => _collection.doc().id;

  /// Uploads a single photo to
  /// `maintenanceRequests/{requestId}/photo_{index}.jpg` and returns its
  /// public download URL.
  Future<String> uploadPhoto({
    required String requestId,
    required int index,
    required File file,
  }) async {
    try {
      final Reference ref = _storage
          .ref()
          .child(AppConstants.requestPhotosStoragePath)
          .child(requestId)
          .child('photo_$index.jpg');
      final UploadTask task = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final TaskSnapshot snap = await task;
      return snap.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw RequestException(_messageForCode(e.code));
    }
  }

  /// Persists the request document. Caller is responsible for uploading any
  /// photos first and passing their download URLs in [photoUrls].
  Future<MaintenanceRequest> createRequest({
    required String id,
    required String propertyId,
    required String landlordId,
    required String tenantId,
    required String title,
    required String description,
    required RequestCategory category,
    required RequestUrgency urgency,
    required List<String> photoUrls,
  }) async {
    try {
      final MaintenanceRequest request = MaintenanceRequest(
        id: id,
        propertyId: propertyId,
        landlordId: landlordId,
        tenantId: tenantId,
        title: title.trim(),
        description: description.trim(),
        category: category,
        urgency: urgency,
        status: RequestStatus.submitted,
        photoUrls: photoUrls,
      );
      await _collection.doc(id).set(request.toFirestoreCreate());
      return request;
    } on FirebaseException catch (e) {
      throw RequestException(_messageForCode(e.code));
    }
  }

  /// Updates only the [status] field and bumps `updatedAt` to the server
  /// timestamp. Firestore rules constrain landlords to this exact diff.
  Future<void> updateStatus({
    required String id,
    required RequestStatus status,
  }) async {
    try {
      await _collection.doc(id).update(<String, Object?>{
        'status': status.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw RequestException(_messageForCode(e.code));
    }
  }

  /// Writes the four AI fields plus the `aiAnalyzedAt` server timestamp.
  /// Firestore rules constrain this to the request's tenant or landlord.
  Future<void> applyAiAnalysis({
    required String id,
    required AiAnalysis analysis,
  }) async {
    try {
      await _collection.doc(id).update(<String, Object?>{
        'aiSummary': analysis.aiSummary,
        'likelyTrade': analysis.likelyTrade,
        'urgencySuggestion': analysis.urgencySuggestion,
        'contractorMessage': analysis.contractorMessage,
        'aiAnalyzedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw RequestException(_messageForCode(e.code));
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
      case 'unauthorized':
        return "You don't have permission to perform that action.";
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Please try again.';
      case 'canceled':
        return 'Upload was cancelled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
