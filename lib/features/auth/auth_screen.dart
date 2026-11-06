import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../core/error_handler.dart';
import '../../widgets/nex_input.dart';
import '../../widgets/nex_button.dart';
import '../../widgets/nex_card.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardBackground = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);

    return Scaffold(
      body: Container(
        color: backgroundColor,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.remote_desktop,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isLogin ? AppLocalizations.of(context)!.signInToNex : AppLocalizations.of(context)!.createAccount,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin
                        ? AppLocalizations.of(context)!.accessRemoteDevices
                        : AppLocalizations.of(context)!.startControllingDevices,
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  NexCard(
                    padding: const EdgeInsets.all(24),
                    color: cardBackground,
                    enableShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isLogin) ...[
                          NexInput(
                            controller: _nameController,
                            label: AppLocalizations.of(context)!.nameLabel,
                            prefixIcon: Icons.person_outline,
                            errorText: _nameError,
                          ),
                          const SizedBox(height: 16),
                        ],
                        NexInput(
                          controller: _emailController,
                          label: AppLocalizations.of(context)!.emailLabel,
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),
                        NexInput(
                          controller: _passwordController,
                          label: AppLocalizations.of(context)!.passwordLabel,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          errorText: _passwordError,
                        ),
                        const SizedBox(height: 24),
                        if (_timeout)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              AppLocalizations.of(context)!.requestTimedOut,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30), 
                                fontSize: 13
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        NexButton(
                          text: isLogin ? AppLocalizations.of(context)!.signIn : AppLocalizations.of(context)!.createAccountBtn,
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
                          ? AppLocalizations.of(context)!.noAccountSignUp
                          : AppLocalizations.of(context)!.hasAccountSignIn,
                      style: TextStyle(
                        fontSize: 13, 
                        color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)
                      ),
                    ),
                  ),
                ],
              ),
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
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _nameError = null;
      _timeout = false;
    });

    bool valid = true;
    if (email.isEmpty) {
      setState(() => _emailError = l10n.emailRequired);
      valid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _emailError = l10n.validEmail);
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _emailError = l10n.passwordRequired);
      valid = false;
    } else if (password.length < 8) {
      setState(() => _emailError = l10n.passwordMinLength);
      valid = false;
    }
    if (!isLogin && name.isEmpty) {
      setState(() => _nameError = l10n.nameRequired);
      valid = false;
    }
    if (!valid) return;

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.requestFailed(e.toString().replaceAll('Exception: ', '')))),
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
      final message = auth.lastError ?? (isLogin ? l10n.loginFailed : l10n.registrationFailed);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
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
