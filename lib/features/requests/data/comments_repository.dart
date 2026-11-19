import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/user_role.dart';
import '../domain/activity_event.dart';
import '../domain/request_comment.dart';

class CommentsException implements Exception {
  CommentsException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads + writes the per-request `comments` and `activity` subcollections.
///
/// Activity events written here are user-initiated (currently just the
/// "submitted" placeholder we don't expose yet). Status- and assignment-
/// driven activity events are emitted from [RequestRepository] inside the
/// same batched write that mutates the request, so the audit trail stays
/// consistent with the parent doc.
class CommentsRepository {
  CommentsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _requestRef(String requestId) =>
      _firestore
          .collection(AppConstants.maintenanceRequestsCollection)
          .doc(requestId)
          .collection('comments');

  CollectionReference<Map<String, dynamic>> _activityRef(String requestId) =>
      _firestore
          .collection(AppConstants.maintenanceRequestsCollection)
          .doc(requestId)
          .collection('activity');

  Stream<List<RequestComment>> watchComments(String requestId) {
    return _requestRef(requestId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(RequestComment.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<ActivityEvent>> watchActivity(String requestId) {
    return _activityRef(requestId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(ActivityEvent.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<RequestComment> addComment({
    required String requestId,
    required String senderId,
    required String senderName,
    required UserRole senderRole,
    required String text,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _requestRef(requestId).doc();
      final RequestComment comment = RequestComment(
        id: ref.id,
        requestId: requestId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        text: text.trim(),
      );
      await ref.set(comment.toFirestoreCreate());
      return comment;
    } on FirebaseException catch (e) {
      throw CommentsException(_messageForCode(e.code));
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return "You don't have permission to comment on this request.";
      case 'unavailable':
        return 'Network error. Please try again.';
      default:
        return 'Could not post comment. Please try again.';
    }
  }
}
