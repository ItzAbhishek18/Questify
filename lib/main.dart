import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/home_screen.dart';

final AuthService authService = AuthService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QuestifyApp());
}

class QuestifyApp extends StatelessWidget {
  const QuestifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Questify',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.cream,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.data != null) {
            return HomeScreen(authService: authService);
          }
          return WelcomeScreen(authService: authService);
        },
      ),
    );
  }
}
