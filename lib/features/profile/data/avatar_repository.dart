import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class AvatarException implements Exception {
  AvatarException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uploads avatar JPEGs to `users/{uid}/avatar.jpg` and returns the public
/// download URL. The path is stable so re-uploads overwrite the previous
/// avatar — no orphan files.
class AvatarRepository {
  AvatarRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    try {
      final Reference ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('avatar.jpg');
      final TaskSnapshot snap = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return snap.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'unauthorized':
        case 'permission-denied':
          throw AvatarException("You don't have permission to upload that.");
        default:
          throw AvatarException('Could not upload your photo.');
      }
    }
  }
}
