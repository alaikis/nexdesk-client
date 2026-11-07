import 'package:flutter/material.dart';
import '../../core/two_factor_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/nex_button.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final TwoFactorService _service = TwoFactorService();
  bool _enabled = false;
  bool _loading = true;
  String? _secret;
  String? _otpauthUrl;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final enabled = await _service.isEnabled();
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _setup() async {
    final secret = await _service.setupTOTP();
    final otpauthUrl = await _service.getOtpAuthUrl();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _secret = secret;
      _otpauthUrl = otpauthUrl;
    });
    if (secret != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanSecret)),
      );
    }
  }

  Future<void> _enable() async {
    final ok = await _service.enableTOTP();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (ok) {
      setState(() => _enabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.twoFactorEnabled)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToEnable2FA)),
      );
    }
  }

  Future<void> _disable() async {
    final ok = await _service.disableTOTP();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (ok) {
      setState(() => _enabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.twoFactorDisabled)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToDisable2FA)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final successColor = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
    final warningColor = isDark ? const Color(0xFFFF9F0A) : const Color(0xFFFF9500);

    final statusBg = _enabled
        ? successColor.withOpacity(0.08)
        : warningColor.withOpacity(0.08);
    final statusIconColor = _enabled ? successColor : warningColor;
    final statusIcon = _enabled ? Icons.verified_user_outlined : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.twoFactorAuthTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                NexCard(
                  color: cardColor,
                  enableShadow: true,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(NexRadius.lg),
                        ),
                        child: Icon(statusIcon, color: statusIconColor, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _enabled ? l10n.twoFactorIsEnabled : l10n.twoFactorIsDisabled,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(
                        _enabled ? 'Enabled' : 'Disabled',
                        isSuccess: _enabled,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_secret != null) ...[
                  NexCard(
                    color: Colors.white,
                    enableShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code_2, color: primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Text(l10n.secretKey, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(NexRadius.md),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _secret!,
                                  style: NexTextStyles.mono(color: textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.copy, size: 18, color: primaryColor),
                                onPressed: () {
                                  // Copy to clipboard handled by SelectableText
                                },
                                tooltip: 'Copy',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        if (_otpauthUrl != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.link, color: primaryColor, size: 22),
                              const SizedBox(width: 8),
                              Text(l10n.manualEntryUrl, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(NexRadius.md),
                            ),
                            child: SelectableText(
                              _otpauthUrl!,
                              style: NexTextStyles.mono(color: textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  NexCard(
                    color: cardColor,
                    enableShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Steps to set up',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _buildStep(1, 'Open your authenticator app', textPrimary, primaryColor),
                        const SizedBox(height: 8),
                        _buildStep(2, 'Scan the QR code or enter the secret key manually', textPrimary, primaryColor),
                        const SizedBox(height: 8),
                        _buildStep(3, 'Enter the 6-digit verification code', textPrimary, primaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!_enabled) ...[
                  NexButton(
                    text: l10n.setupAuthenticator,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    fullWidth: true,
                    onPressed: _setup,
                  ),
                  if (_secret != null) ...[
                    const SizedBox(height: 12),
                    NexButton(
                      text: l10n.enable2FA,
                      icon: const Icon(Icons.verified_user, size: 18),
                      fullWidth: true,
                      onPressed: _enable,
                    ),
                  ],
                ] else ...[
                  NexButton(
                    text: l10n.disable2FA,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    variant: NexButtonVariant.destructive,
                    fullWidth: true,
                    onPressed: _disable,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusBadge(String text, {required bool isSuccess, required bool isDark}) {
    final successBg = isDark ? const Color(0xFF30D158).withOpacity(0.15) : const Color(0xFF34C759).withOpacity(0.12);
    final successFg = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
    final warningBg = isDark ? const Color(0xFFFF9F0A).withOpacity(0.15) : const Color(0xFFFF9500).withOpacity(0.12);
    final warningFg = isDark ? const Color(0xFFFF9F0A) : const Color(0xFFFF9500);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? successBg : warningBg,
        borderRadius: BorderRadius.circular(NexRadius.full),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSuccess ? successFg : warningFg,
        ),
      ),
    );
  }

  Widget _buildStep(int number, String description, Color textPrimary, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(NexRadius.full),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: TextStyle(fontSize: 15, color: textPrimary, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
