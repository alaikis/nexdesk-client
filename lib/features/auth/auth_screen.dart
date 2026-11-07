import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../core/error_handler.dart';
import '../../widgets/nex_button.dart';
import '../../widgets/nex_card.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with ErrorHandler {
  bool _loading = false;
  String? _error;

  Future<void> _startSSO() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.startSSOLogin();

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _error = auth.lastError ?? 'Failed to start login';
        _loading = false;
      });
    }
    // 轮询由 AuthProvider 的 notifyListeners 驱动 UI 更新
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardBackground = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);

    final isPolling = auth.ssoPolling;

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
                        if (_error != null || auth.lastError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error ?? auth.lastError!,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (isPolling) ...[
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for login in browser...',
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
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              auth.cancelSSOLogin();
                              setState(() => _loading = false);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ] else
                          NexButton(
                            text: 'Sign in with Browser',
                            fullWidth: true,
                            loading: _loading,
                            icon: const Icon(Icons.open_in_browser, size: 18),
                            onPressed: _loading ? null : _startSSO,
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