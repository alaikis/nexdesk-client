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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFE34234) : const Color(0xFFE34234);
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);
    final errorColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C);
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
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
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(NexRadius.lg),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.twoFactorAuthTitle,
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
                  l10n.enterCodeHint,
                  style: TextStyle(fontSize: 15, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                NexCard(
                  padding: const EdgeInsets.all(24),
                  color: cardColor,
                  enableShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) => _buildDigitBox(index, isDark, primaryColor, borderColor, textPrimary)),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(NexRadius.md),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 13, color: errorColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      NexButton(
                        text: l10n.verify,
                        fullWidth: true,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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

  Widget _buildDigitBox(int index, bool isDark, Color primaryColor, Color borderColor, Color textPrimary) {
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
          color: textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NexRadius.md),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NexRadius.md),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NexRadius.md),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
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
