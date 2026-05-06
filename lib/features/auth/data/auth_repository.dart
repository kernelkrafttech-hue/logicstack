import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Wraps Firebase Auth and the `users/{uid}` Firestore document.
///
/// All UI code goes through this repository so we have one place to translate
/// Firebase errors into friendly messages and to keep the user profile
/// document in sync with the auth user.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<AppUser?> fetchAppUser(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  Stream<AppUser?> watchAppUser(String uid) {
    return _users.doc(uid).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snap) {
        if (!snap.exists) return null;
        return AppUser.fromFirestore(snap);
      },
    );
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User user = credential.user!;
      await user.updateDisplayName(displayName.trim());

      final AppUser appUser = AppUser(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        role: role,
      );
      await _users.doc(user.uid).set(appUser.toFirestore());
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForCode(e.code));
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final AppUser? appUser = await fetchAppUser(credential.user!.uid);
      if (appUser == null) {
        throw AuthException(
          'Your account is missing a profile. Please contact support.',
        );
      }
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForCode(e.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForCode(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 8 characters).';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
