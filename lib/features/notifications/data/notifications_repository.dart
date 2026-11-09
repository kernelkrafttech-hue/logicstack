import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/app_notification.dart';

class NotificationsException implements Exception {
  NotificationsException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads (and marks as read) the current user's notifications. Writes are
/// handled server-side by the notification trigger Cloud Functions.
class NotificationsRepository {
  NotificationsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _windowSize = 50;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.notificationsCollection);

  /// Live list of the most recent notifications for [userId], newest first.
  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_windowSize)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(AppNotification.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> markRead(String id) async {
    try {
      await _collection.doc(id).update(<String, Object?>{'read': true});
    } on FirebaseException catch (e) {
      throw NotificationsException(_messageForCode(e.code));
    }
  }

  /// Flips `read: true` on every notification in [ids] in a single batch.
  Future<void> markManyRead(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final WriteBatch batch = _firestore.batch();
      for (final String id in ids) {
        batch.update(
          _collection.doc(id),
          <String, Object?>{'read': true},
        );
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw NotificationsException(_messageForCode(e.code));
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return "You don't have permission to update this notification.";
      case 'unavailable':
        return 'Network error. Please try again.';
      default:
        return 'Could not update notification.';
    }
  }
}
