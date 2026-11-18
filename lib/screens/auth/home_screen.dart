import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.authService,
  });

  Future<void> _signOut(BuildContext context) async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('QUESTIFY'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 58,
                  color: AppTheme.warmStone,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.mutedGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.displayName ?? user?.email ?? 'Questifier',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedGreen,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _signOut(context),
                child: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
