import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<UserProvider>().login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      // Navigation is handled by GoRouter redirect
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        
        // Parse Firebase error messages
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('user-not-found') || errorStr.contains('user not found')) {
          errorMessage = 'No account found with this email';
        } else if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
          errorMessage = 'Incorrect password';
        } else if (errorStr.contains('invalid-email')) {
          errorMessage = 'Invalid email format';
        } else if (errorStr.contains('user-disabled')) {
          errorMessage = 'This account has been disabled';
        } else if (errorStr.contains('too-many-requests')) {
          errorMessage = 'Too many attempts. Please try again later';
        } else if (errorStr.contains('network')) {
          errorMessage = 'Network error. Check your connection';
        } else {
          // Show the original error if it's not a common case
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     const Icon(Icons.quiz, size: 80, color: Colors.deepPurple),
                     const SizedBox(height: 32),
                     Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                     ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                     const SizedBox(height: 32),
                     TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                     ).animate().fadeIn(delay: 200.ms),
                     const SizedBox(height: 16),
                     TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                     ).animate().fadeIn(delay: 300.ms),
                     const SizedBox(height: 24),
                     SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Text('Login'),
                      ),
                     ).animate().fadeIn(delay: 400.ms),
                     const SizedBox(height: 24),
                     TextButton.icon(
                       onPressed: () => GoRouter.of(context).push('/about'),
                       icon: const Icon(Icons.info_outline, size: 16),
                       label: const Text('About Us'),
                     ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
