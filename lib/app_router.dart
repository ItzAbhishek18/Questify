import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/achievements_screen.dart';
import 'screens/create_quest_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/quest_detail_screen.dart';
import 'screens/quests_screen.dart';
import 'screens/settings_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const quests = '/quests';
  static const achievements = '/achievements';
  static const profile = '/profile';
  static const questDetail = '/quest/:id';
  static const createQuest = '/create-quest';
  static const progress = '/progress';
  static const settings = '/settings';
}

/// Re-runs the router's redirect whenever the auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final atLogin = state.matchedLocation == AppRoutes.login;

    if (!loggedIn && !atLogin) return AppRoutes.login;
    if (loggedIn && atLogin) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    // The four tabs share one bottom navigation bar.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.quests,
            name: 'quests',
            builder: (context, state) => const QuestsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.achievements,
            name: 'achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
    // Full-screen pages that open on top of the tabs.
    GoRoute(
      path: AppRoutes.questDetail,
      name: 'questDetail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return QuestDetailScreen(questId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.createQuest,
      name: 'createQuest',
      builder: (context, state) => const CreateQuestScreen(),
    ),
    GoRoute(
      path: AppRoutes.progress,
      name: 'progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
