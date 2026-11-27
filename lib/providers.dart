import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/quest_model.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/goals_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final UserModel? userProfile;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.userProfile,
  });

  const AuthState.uninitialized()
      : status = AuthStatus.uninitialized,
        user = null,
        errorMessage = null,
        userProfile = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null,
        userProfile = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null,
        userProfile = null;

  const AuthState.authenticated(User authenticatedUser, {UserModel? profile})
      : status = AuthStatus.authenticated,
        user = authenticatedUser,
        errorMessage = null,
        userProfile = profile;

  const AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        errorMessage = message,
        userProfile = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error;
}

/// Mirrors Firebase auth state and the signed-in user's live profile.
/// All sign-in / sign-up / sign-out work is delegated to [AuthService].
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required this.authService,
    required this.firebaseAuth,
    required this.firestore,
  }) : super(const AuthState.uninitialized()) {
    _authSub = firebaseAuth.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService authService;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  void _onAuthChanged(User? user) {
    _profileSub?.cancel();
    _profileSub = null;

    if (user == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    state = AuthState.authenticated(user);

    // Live profile: XP, level and streaks update on screen as they change.
    _profileSub = firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      // The document may not exist for a moment right after sign-up.
      if (!mounted || !doc.exists) return;
      final current = state.user;
      if (current == null || current.uid != user.uid) return;
      state = AuthState.authenticated(
        current,
        profile: UserModel.fromFirestore(doc),
      );
    }, onError: (_) {
      // Keep the current auth state if the profile can't be read.
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await authService.signInWithEmail(email: email, password: password);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await authService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> signOut() async {
    await authService.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await authService.resetPassword(email: email);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authService: ref.read(authServiceProvider),
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final userProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).userProfile;
});

// ---- Quest streams -------------------------------------------------------
// Each one watches the signed-in user's uid, so the stream restarts whenever
// the account changes and a previous user's quests are never shown.

final questsProvider = StreamProvider.autoDispose<List<QuestModel>>((ref) {
  ref.watch(authProvider.select((s) => s.user?.uid));
  return ref.watch(goalsServiceProvider).getQuests();
});

final activeQuestsProvider =
StreamProvider.autoDispose<List<QuestModel>>((ref) {
  ref.watch(authProvider.select((s) => s.user?.uid));
  return ref.watch(goalsServiceProvider).getActiveQuests();
});

final completedQuestsProvider =
StreamProvider.autoDispose<List<QuestModel>>((ref) {
  ref.watch(authProvider.select((s) => s.user?.uid));
  return ref.watch(goalsServiceProvider).getCompletedQuests();
});