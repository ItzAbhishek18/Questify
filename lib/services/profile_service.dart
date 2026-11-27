import "dart:convert";
import "dart:typed_data";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Saves the profile picture as a small base64 string in users/{uid}.
/// (Firebase Storage needs a paid plan for new projects, so it is not used.)
class ProfileService {
  ProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const int maxBytes = 200 * 1024;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError("You must be signed in.");
    return _firestore.collection("users").doc(uid);
  }

  Future<void> setPhoto(Uint8List bytes) async {
    if (bytes.length > maxBytes) {
      throw Exception("That picture is too large. Please choose a smaller one.");
    }
    await _userDoc
        .set({"photoBase64": base64Encode(bytes)}, SetOptions(merge: true));
  }

  Future<void> removePhoto() async {
    await _userDoc
        .set({"photoBase64": FieldValue.delete()}, SetOptions(merge: true));
  }
}

final profileServiceProvider = Provider((ref) => ProfileService());
