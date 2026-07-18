import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  const AuthScreen({super.key, required this.mode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;

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
                  ),
                  const SizedBox(height: 12),
                ],
                _GlassTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _GlassTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
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
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      context.go('/devices');
    });
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

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
      ),
      style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 15),
    );
  }
}
