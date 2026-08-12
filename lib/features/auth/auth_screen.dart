import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../core/error_handler.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  const AuthScreen({super.key, required this.mode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with ErrorHandler {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FlutterLogo(size: 56),
                const SizedBox(height: 28),
                Text(
                  isLogin ? 'Sign in' : 'Create account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  isLogin
                      ? 'Access your remote devices securely.'
                      : 'Start controlling devices with WebRTC.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (!isLogin) ...[
                  _GlassTextField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline,
                    errorText: _nameError,
                  ),
                  const SizedBox(height: 12),
                ],
                _GlassTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 12),
                _GlassTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  errorText: _passwordError,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                    : SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(isLogin ? 'Sign In' : 'Create Account'),
                        ),
                      ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    final newMode = isLogin ? AuthMode.register : AuthMode.login;
                    context.go(newMode == AuthMode.login ? '/login' : '/register');
                  },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                    style: TextStyle(fontSize: 13, color: hintColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final isLogin = widget.mode == AuthMode.login;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
      _nameError = null;
    });

    bool valid = true;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      valid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      valid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      valid = false;
    }
    if (!isLogin && name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      valid = false;
    }
    if (!valid) return;

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    bool ok = false;
    try {
      ok = await (isLogin
          ? auth.login(email, password)
          : auth.register(email, password, name)).timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
      ok = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (ok) {
      if (mounted) context.go('/devices');
    } else if (auth.requires2FA) {
      if (mounted) context.go('/2fa');
    } else {
      final message = auth.lastError ?? (isLogin ? 'Login failed' : 'Registration failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: labelColor),
        errorText: errorText,
      ),
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F),
        fontSize: 15,
      ),
    );
  }
}
