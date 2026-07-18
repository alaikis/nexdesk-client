import 'package:flutter/material.dart';
import '../../core/two_factor_service.dart';

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
    setState(() {
      _secret = secret;
      _otpauthUrl = otpauthUrl;
    });
    if (secret != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan this secret with your authenticator app')),
      );
    }
  }

  Future<void> _enable() async {
    final code = await _promptCode('Enter 6-digit code');
    if (code == null) return;
    final ok = await _service.enableTOTP(code);
    if (!mounted) return;
    if (ok) {
      setState(() => _enabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2FA enabled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to enable 2FA')),
      );
    }
  }

  Future<void> _disable() async {
    final code = await _promptCode('Enter 6-digit code to disable');
    if (code == null) return;
    final ok = await _service.disableTOTP(code);
    if (!mounted) return;
    if (ok) {
      setState(() => _enabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2FA disabled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to disable 2FA')),
      );
    }
  }

  Future<String?> _promptCode(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('OK')),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
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
                            _enabled ? '2FA is enabled' : '2FA is disabled',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_secret != null) ...[
                    const Text('Secret key:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _secret!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_otpauthUrl != null) ...[
                      const Text('Manual entry URL:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      label: const Text('Setup Authenticator'),
                    ),
                    if (_secret != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _enable,
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Enable 2FA'),
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
                      label: const Text('Disable 2FA'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
