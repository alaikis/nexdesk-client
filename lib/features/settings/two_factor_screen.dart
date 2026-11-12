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
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final backgroundColor = wise.background;
    final cardColor = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final surfaceColor = wise.surface;
    final successColor = wise.success;
    final warningColor = wise.warning;

    final statusBg = _enabled
        ? wise.successSoft
        : wise.warningSoft;
    final statusIconColor = _enabled ? successColor : warningColor;
    final statusIcon = _enabled ? Icons.verified_user_outlined : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.twoFactorAuthTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(wise.spacing.xl),
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
                          borderRadius: BorderRadius.circular(wise.radius.lg),
                        ),
                        child: Icon(statusIcon, color: statusIconColor, size: 28),
                      ),
                      SizedBox(height: wise.spacing.lg),
                      Text(
                        _enabled ? l10n.twoFactorIsEnabled : l10n.twoFactorIsDisabled,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary, height: 1.47),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: wise.spacing.sm),
                      _buildStatusBadge(
                        _enabled ? 'Enabled' : 'Disabled',
                        isSuccess: _enabled,
                        context: context,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: wise.spacing.lg),
                if (_secret != null) ...[
                  NexCard(
                    color: cardColor,
                    enableShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code_2, color: primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Text(l10n.secretKey, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53)),
                          ],
                        ),
                        SizedBox(height: wise.spacing.md),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(wise.spacing.md),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(wise.radius.medium),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _secret!,
                                  style: TextStyle(color: textPrimary, fontFamily: WiseTypographyTokens.monoFamily, fontSize: 13),
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
                          SizedBox(height: wise.spacing.md),
                          Row(
                            children: [
                              Icon(Icons.link, color: primaryColor, size: 22),
                              const SizedBox(width: 8),
                              Text(l10n.manualEntryUrl, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53)),
                            ],
                          ),
                          SizedBox(height: wise.spacing.sm),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(wise.spacing.md),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(wise.radius.medium),
                            ),
                            child: SelectableText(
                              _otpauthUrl!,
                              style: TextStyle(color: textSecondary, fontFamily: WiseTypographyTokens.monoFamily, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: wise.spacing.lg),
                  NexCard(
                    color: cardColor,
                    enableShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Steps to set up',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53),
                        ),
                        SizedBox(height: wise.spacing.md),
                        _buildStep(1, 'Open your authenticator app', textPrimary, primaryColor),
                        SizedBox(height: wise.spacing.sm),
                        _buildStep(2, 'Scan the QR code or enter the secret key manually', textPrimary, primaryColor),
                        SizedBox(height: wise.spacing.sm),
                        _buildStep(3, 'Enter the 6-digit verification code', textPrimary, primaryColor),
                      ],
                    ),
                  ),
                  SizedBox(height: wise.spacing.lg),
                ],
                if (!_enabled) ...[
                  NexButton(
                    text: l10n.setupAuthenticator,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    fullWidth: true,
                    onPressed: _setup,
                  ),
                  if (_secret != null) ...[
                    SizedBox(height: wise.spacing.md),
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

  Widget _buildStatusBadge(String text, {required bool isSuccess, required BuildContext context}) {
    final wise = WiseTheme.of(context);
    final successBg = wise.successSoft;
    final successFg = wise.success;
    final warningBg = wise.warningSoft;
    final warningFg = wise.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? successBg : warningBg,
        borderRadius: BorderRadius.circular(wise.radius.full),
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
    final wise = WiseTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(wise.radius.full),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: wise.onPrimary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: TextStyle(fontSize: 15, color: textPrimary, height: 1.53),
            ),
          ),
        ),
      ],
    );
  }
}
