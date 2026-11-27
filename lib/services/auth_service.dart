import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questify/models/user_model.dart';

/// A readable error that screens can show directly to the user.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        // A profile problem must not make a successful login look failed.
        try {
          await _touchUserProfile(user);
        } catch (_) {}
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await _createUserProfile(
          user: user,
          displayName: displayName,
          email: email,
        );
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on FirebaseException catch (e) {
      // Firestore failed after the account was created.
      throw AuthException(
        'Account created, but saving your profile failed (${e.code}). '
            'Check your Firestore rules.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'photoURL': photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Sends a verification link to the new address. The email in Auth only
  /// changes after the user clicks it, so Firestore is NOT updated here.
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      case 'requires-recent-login':
        return 'For security, please sign out and sign in again, then retry.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }

  Future<void> _createUserProfile({
    required User user,
    required String displayName,
    required String email,
  }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': displayName,
      'email': email,
      'photoURL': user.photoURL,
      'questsCompleted': 0,
      'goalsCompleted': 0,
      'totalXp': 0,
      'level': 1,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastCompletionDate': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  /// On login: update lastLogin only. If the profile document is missing
  /// (e.g. an earlier write failed), create it. Never overwrite the name.
  Future<void> _touchUserProfile(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({'lastLogin': FieldValue.serverTimestamp()});
    } else {
      await _createUserProfile(
        user: user,
        displayName: user.displayName ?? (user.email ?? '').split('@').first,
        email: user.email ?? '',
      );
    }
  }
}

final authServiceProvider = Provider((ref) => AuthService());