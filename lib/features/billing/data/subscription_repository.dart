import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/subscription.dart';

/// Read-only client view of the subscription state. The webhook + trial
/// seed Cloud Functions are the only writers — clients never poke this doc
/// directly, so there's no `set`/`update` here.
class SubscriptionRepository {
  SubscriptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.subscriptionSubcollection)
      .doc(AppConstants.currentSubscriptionDocId);

  /// Live current subscription. Emits `null` when no doc exists yet (e.g.
  /// the trial seed hasn't fired or the user hasn't completed signup).
  Stream<Subscription?> watchCurrent(String uid) {
    return _doc(uid).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snap) {
        if (!snap.exists) return null;
        return Subscription.fromFirestore(snap);
      },
    );
  }
}
