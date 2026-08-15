import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/nex_card.dart';
import '../../l10n/app_localizations.dart';
import '../../app.dart';
import 'two_factor_screen.dart';
import 'security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _baseUrl = 'https://nex.hottol.com';
  String _version = '0.1.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = '${info.version} (${info.buildNumber})';
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _launchUrl(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.cannotOpenLink(path).replaceFirst('{path}', path) ?? 'Cannot open link: $path')),
      );
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    await NexApp.setLocale(Locale(langCode));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.settings, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 20),
        NexCard(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.security),
                subtitle: Text(l10n.manageSecuritySettings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SecuritySettingsScreen(
                        deviceId: 'current',
                        device: const {},
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.twoFactorAuth),
                subtitle: Text(l10n.manage2FASettings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TwoFactorScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NexCard(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.language),
                subtitle: Text(l10n.selectLanguage),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _changeLanguage(value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'en',
                      child: Text(l10n.english),
                    ),
                    PopupMenuItem(
                      value: 'zh',
                      child: Text(l10n.chinese),
                    ),
                  ],
                  child: const Icon(Icons.language),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NexCard(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.privacyPolicy),
                subtitle: Text(l10n.viewPrivacyPolicy),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchUrl('/legal/privacy'),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.termsOfService),
                subtitle: Text(l10n.viewTermsOfService),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchUrl('/legal/terms'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.versionInfo(_version), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}
