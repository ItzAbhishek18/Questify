import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  final AuthService authService;

  const SignUpScreen({
    super.key,
    required this.authService,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await widget.authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save user's name in Firebase Authentication profile.
      try {
        await userCredential.user?.updateDisplayName(
          _nameController.text.trim(),
        );
        await userCredential.user?.reload();
      } catch (_) {
        // Account was created; non-fatal profile update failure.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppTheme.forestGreen,
        ),
      );

      // Return to the previous screen after successful registration.
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'weak-password':
          message = 'Your password is too weak.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'operation-not-allowed':
          message = 'Email/password registration is currently disabled.';
          break;

        default:
          message = e.message ?? 'Registration failed. Please try again.';
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
                    'START YOUR JOURNEY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppTheme.forestGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Create an account and turn your goals into quests.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedGreen,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Full Name
                  const Text(
                    'Full Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

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

                  // Password
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Create a password',
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
                        return 'Please create a password';
                      }

                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password
                  const Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Create Account Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
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
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
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

                  // Google Sign Up
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

                  // Login navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppTheme.mutedGreen,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: AppTheme.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
