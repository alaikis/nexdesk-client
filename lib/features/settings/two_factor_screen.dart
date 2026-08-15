import 'package:flutter/material.dart';
import '../../core/two_factor_service.dart';
import '../../l10n/app_localizations.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.twoFactorAuthTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _enabled ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _enabled ? Icons.verified_user : Icons.warning_amber_rounded,
                          color: _enabled ? const Color(0xFF34C759) : const Color(0xFFFF9800),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _enabled ? l10n.twoFactorIsEnabled : l10n.twoFactorIsDisabled,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_secret != null) ...[
                    Text(l10n.secretKey, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _secret!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_otpauthUrl != null) ...[
                      Text(l10n.manualEntryUrl, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SelectableText(
                        _otpauthUrl!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (!_enabled) ...[
                    ElevatedButton.icon(
                      onPressed: _setup,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(l10n.setupAuthenticator),
                    ),
                    if (_secret != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _enable,
                        icon: const Icon(Icons.verified_user),
                        label: Text(l10n.enable2FA),
                      ),
                    ],
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _disable,
                      icon: const Icon(Icons.remove_circle_outline),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                      ),
                      label: Text(l10n.disable2FA),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
