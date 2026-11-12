import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../core/error_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/nex_button.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> with ErrorHandler {
  final _codeController = TextEditingController();
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _digitControllers = List.generate(6, (_) => TextEditingController());
  bool _loading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wise = WiseTheme.of(context);

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
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: wise.primary,
                      borderRadius: BorderRadius.circular(wise.radius.lg),
                    ),
                    child: Icon(
                      Icons.security,
                      color: wise.onPrimary,
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(height: wise.spacing.xxl),
                Text(
                  l10n.twoFactorAuthTitle,
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
                  l10n.enterCodeHint,
                  style: TextStyle(fontSize: 15, color: wise.textSecondary, height: 1.53),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: wise.spacing.xxl),
                NexCard(
                  padding: EdgeInsets.all(wise.spacing.xxl),
                  color: wise.card,
                  enableShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) => _buildDigitBox(index, wise)),
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: wise.spacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: wise.errorSoft,
                            borderRadius: BorderRadius.circular(wise.radius.medium),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 13, color: wise.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      SizedBox(height: wise.spacing.xxl),
                      NexButton(
                        text: l10n.verify,
                        fullWidth: true,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: wise.spacing.lg),
                Center(
                  child: NexButton(
                    text: l10n.backToSignIn,
                    variant: NexButtonVariant.ghost,
                    size: NexButtonSize.small,
                    onPressed: () => context.go('/login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index, WiseTheme wise) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: wise.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: wise.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(wise.radius.medium),
            borderSide: BorderSide(color: wise.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(wise.radius.medium),
            borderSide: BorderSide(color: wise.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(wise.radius.medium),
            borderSide: BorderSide(color: wise.primary, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  void _submit() async {
    final code = _digitControllers.map((c) => c.text).join();
    final l10n = AppLocalizations.of(context)!;
    if (code.length < 6) {
      setState(() => _errorMessage = l10n.enter6DigitCode);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.verify2FA(code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      context.go('/devices');
    } else {
      final message = auth.lastError ?? l10n.verificationFailed;
      setState(() => _errorMessage = message);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
