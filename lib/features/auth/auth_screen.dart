import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../widgets/nex_button.dart';
import '../../widgets/nex_card.dart';
import '../../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _error;

  Future<void> _startSSO() async {
    setState(() {
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.startSSOLogin();

    if (!mounted) return;
    if (!ok) {
      setState(() => _error = auth.lastError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7);
    final cardBackground = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);

    final inProgress = auth.ssoInProgress;
    final activeError = _error ?? auth.lastError;

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
                        color: const Color(0xFFE34234),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.desktop_windows,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.signInToNex,
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
                    l10n.accessRemoteDevices,
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
                        if (activeError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              activeError!,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (inProgress) ...[
                          Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? const Color(0xFFE34234) : const Color(0xFFE34234),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for browser sign-in...',
                            style: TextStyle(
                              fontSize: 15,
                              color: textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete sign-in in your browser, then return here.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else
                          NexButton(
                            text: 'Sign in with Browser',
                            fullWidth: true,
                            icon: const Icon(Icons.open_in_browser, size: 18),
                            onPressed: _startSSO,
                          ),
                      ],
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
}