import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../core/error_handler.dart';
import '../../widgets/nex_input.dart';
import '../../widgets/nex_button.dart';
import '../../widgets/nex_card.dart';

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
  bool _timeout = false;

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FlutterLogo(size: 48),
                const SizedBox(height: 24),
                Text(
                  isLogin ? 'Sign in to NEX' : 'Create your account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: cs.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Access your remote devices securely.'
                      : 'Start controlling devices with WebRTC.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                NexCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isLogin) ...[
                        NexInput(
                          controller: _nameController,
                          label: 'Name',
                          prefixIcon: Icons.person_outline,
                          errorText: _nameError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      NexInput(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 16),
                      NexInput(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 24),
                      if (_timeout)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Request timed out. Please try again.',
                            style: TextStyle(color: cs.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      NexButton(
                        text: isLogin ? 'Sign In' : 'Create Account',
                        fullWidth: true,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    final newMode = isLogin ? AuthMode.register : AuthMode.login;
                    context.go(newMode == AuthMode.login ? '/login' : '/register');
                  },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
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
      _timeout = false;
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
        onTimeout: () {
          if (mounted) setState(() => _timeout = true);
          return false;
        },
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
