import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({
    super.key,
    required this.authService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Questify logo
                  Center(
                    child: Container(
                      height: 75,
                      width: 75,
                      decoration: BoxDecoration(
                        color: AppTheme.forestGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: AppTheme.warmStone,
                        size: 42,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Heading
                  const Text(
                    'WELCOME BACK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppTheme.forestGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Continue your journey. Your quests await.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedGreen,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Email label
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!RegExp(
                        r'^[\w\.-]+@[\w\.-]+\.\w+$',
                      ).hasMatch(value.trim())) {
                        return 'Please enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password label
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Forgot password will be implemented next.',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppTheme.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // OR divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppTheme.mutedGreen.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google sign-in button
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Google Sign-In will be connected next.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 30,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        54,
                      ),
                      foregroundColor: AppTheme.darkGreen,
                      side: const BorderSide(
                        color: AppTheme.warmStone,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sign-up navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppTheme.mutedGreen,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignUpScreen(
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppTheme.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
