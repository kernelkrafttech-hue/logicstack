import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../contractors/domain/contractor.dart';
import '../domain/activity_event.dart';
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
  Stream<List<MaintenanceRequest>> watchRequestsForLandlord(
    String landlordId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(MaintenanceRequest.fromFirestore)
              .toList(growable: false),
        );
  }

  /// Live list of every request currently assigned to [contractorEmail].
  ///
  /// The contractor is matched by email rather than a uid because contractors
  /// may sign in long after a landlord adds them to their roster. Email is
  /// denormalized onto the request at assignment time.
  Stream<List<MaintenanceRequest>> watchRequestsForContractorEmail(
    String contractorEmail,
  ) {
    return _collection
        .where('contractorEmail', isEqualTo: contractorEmail.toLowerCase())
        .orderBy('assignedAt', descending: true)
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

  DocumentReference<Map<String, dynamic>> _activityDoc(String requestId) =>
      _collection.doc(requestId).collection('activity').doc();

  ActivityEvent _buildEvent({
    required DocumentReference<Map<String, dynamic>> ref,
    required String requestId,
    required ActivityType type,
    required String title,
    required String description,
    required ActivityActor actor,
  }) {
    return ActivityEvent(
      id: ref.id,
      requestId: requestId,
      type: type,
      title: title,
      description: description,
      createdBy: actor.uid,
    );
  }

  /// Persists the request document and seeds the timeline with the
  /// "submitted" activity event in a single batched write.
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
    required ActivityActor actor,
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

      final DocumentReference<Map<String, dynamic>> activityRef =
          _activityDoc(id);
      final ActivityEvent event = _buildEvent(
        ref: activityRef,
        requestId: id,
        type: ActivityType.submitted,
        title: 'Request submitted',
        description: 'Submitted by ${actor.name} (${actor.roleLabel}).',
        actor: actor,
      );

      final WriteBatch batch = _firestore.batch();
      batch.set(_collection.doc(id), request.toFirestoreCreate());
      batch.set(activityRef, event.toFirestoreCreate());
      await batch.commit();
      return request;
    } on FirebaseException catch (e) {
      throw RequestException(_messageForCode(e.code));
    }
  }

  /// Updates the [status] field, bumps `updatedAt`, and appends a
  /// status_changed activity event in one batched write. Firestore rules
  /// allow either branch (landlord or contractor) to write the activity
  /// because both can read the parent request.
  Future<void> updateStatus({
    required String id,
    required RequestStatus status,
    required ActivityActor actor,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> activityRef =
          _activityDoc(id);
      final ActivityEvent event = _buildEvent(
        ref: activityRef,
        requestId: id,
        type: ActivityType.statusChanged,
        title: 'Status changed to ${status.displayName}',
        description: 'Updated by ${actor.name} (${actor.roleLabel}).',
        actor: actor,
      );

      final WriteBatch batch = _firestore.batch();
      batch.update(_collection.doc(id), <String, Object?>{
        'status': status.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(activityRef, event.toFirestoreCreate());
      await batch.commit();
    } on FirebaseException catch (e) {
      throw RequestException(_messageForCode(e.code));
    }
  }

  /// Assigns a contractor to a request, writes the assignment activity
  /// event, and bumps audit timestamps in a single batched write.
  Future<void> assignContractor({
    required String requestId,
    required Contractor contractor,
    required ActivityActor actor,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> activityRef =
          _activityDoc(requestId);
      final ActivityEvent event = _buildEvent(
        ref: activityRef,
        requestId: requestId,
        type: ActivityType.contractorAssigned,
        title: 'Assigned to ${contractor.name}',
        description:
            '${contractor.trade.displayName} · routed by ${actor.name} (${actor.roleLabel}).',
        actor: actor,
      );

      final WriteBatch batch = _firestore.batch();
      batch.update(_collection.doc(requestId), <String, Object?>{
        'contractorId': contractor.id,
        'contractorName': contractor.name,
        'contractorTrade': contractor.trade.storageValue,
        'contractorEmail': contractor.email.toLowerCase(),
        'assignedAt': FieldValue.serverTimestamp(),
        'status': RequestStatus.sentToContractor.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(activityRef, event.toFirestoreCreate());
      await batch.commit();
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
