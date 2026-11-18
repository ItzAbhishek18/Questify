import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openAuthPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthPlaceholderScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),

              // Questify icon
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

              // App name
              const Text(
                'QUESTIFY',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  color: AppTheme.forestGreen,
                ),
              ),

              const SizedBox(height: 12),

              // Tagline
              const Text(
                'Turn your goals into quests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.mutedGreen,
                ),
              ),

              const Spacer(),

              // Get Started button
              ElevatedButton(
                onPressed: () {
                  _openAuthPlaceholder(context, 'Create Account');
                },
                child: const Text(
                  'GET STARTED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Login button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  foregroundColor: AppTheme.forestGreen,
                  side: const BorderSide(
                    color: AppTheme.forestGreen,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'I ALREADY HAVE AN ACCOUNT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Build habits. Complete quests. Level up.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedGreen,
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

// Temporary screen until Login and Registration are implemented.
class AuthPlaceholderScreen extends StatelessWidget {
  final String title;

  const AuthPlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title screen will be implemented next.',
          style: const TextStyle(
            color: AppTheme.forestGreen,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}