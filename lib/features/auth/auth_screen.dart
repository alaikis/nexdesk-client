import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nex_button.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/litchi_logo.dart';
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
    final wise = WiseTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final inProgress = auth.ssoInProgress;
    final activeError = _error ?? auth.lastError;

    return Scaffold(
      backgroundColor: wise.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(wise.spacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: LitchiLogo(size: 64, showBackground: true),
                ),
                SizedBox(height: wise.spacing.xl),
                Text(
                  l10n.signInToNex,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: wise.textPrimary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: wise.spacing.sm),
                Text(
                  l10n.accessRemoteDevices,
                  style: TextStyle(
                    fontSize: 14,
                    color: wise.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: wise.spacing.xxl),
                NexCard(
                  padding: EdgeInsets.all(wise.spacing.xl),
                  color: wise.card,
                  enableShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeError != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: wise.spacing.md),
                          child: Container(
                            padding: EdgeInsets.all(wise.spacing.md),
                            decoration: BoxDecoration(
                              color: wise.errorSoft,
                              borderRadius: BorderRadius.circular(wise.radius.medium),
                              border: Border.all(color: wise.error.withValues(alpha: 0.24)),
                            ),
                            child: Text(
                              activeError,
                              style: TextStyle(
                                color: wise.error,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (inProgress) ...[
                        Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: wise.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: wise.spacing.lg),
                        Text(
                          'Waiting for browser sign-in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: wise.textPrimary,
                            height: 1.57,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: wise.spacing.xs),
                        Text(
                          'Complete sign-in in your browser, then return here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: wise.textSecondary,
                            height: 1.54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else
                        NexButton(
                          text: 'Sign in with browser',
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
    );
  }
}
