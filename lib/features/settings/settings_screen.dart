import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/nex_card.dart';
import '../../theme/app_theme.dart';
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
    final wise = WiseTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: wise.background,
      child: ListView(
        padding: EdgeInsets.all(wise.spacing.xl),
        children: [
          Text(
            l10n.settings,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: wise.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: wise.spacing.xxl),
          NexCard(
            color: wise.card,
            enableShadow: true,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.xs),
                  title: Text(l10n.security, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: wise.textPrimary)),
                  subtitle: Text(l10n.manageSecuritySettings, style: TextStyle(fontSize: 13, color: wise.textSecondary)),
                  trailing: Icon(Icons.chevron_right, color: wise.textTertiary),
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
                Divider(height: 1, color: wise.border),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.xs),
                  title: Text(l10n.twoFactorAuth, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: wise.textPrimary)),
                  subtitle: Text(l10n.manage2FASettings, style: TextStyle(fontSize: 13, color: wise.textSecondary)),
                  trailing: Icon(Icons.chevron_right, color: wise.textTertiary),
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
          SizedBox(height: wise.spacing.md),
          NexCard(
            color: wise.card,
            enableShadow: true,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.xs),
                  title: Text(l10n.language, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: wise.textPrimary)),
                  subtitle: Text(l10n.selectLanguage, style: TextStyle(fontSize: 13, color: wise.textSecondary)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _changeLanguage(value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'en', child: Text(l10n.english)),
                      PopupMenuItem(value: 'zh', child: Text(l10n.chinese)),
                    ],
                    child: Icon(Icons.language, color: wise.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: wise.spacing.md),
          NexCard(
            color: wise.card,
            enableShadow: true,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.xs),
                  title: Text(l10n.privacyPolicy, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: wise.textPrimary)),
                  subtitle: Text(l10n.viewPrivacyPolicy, style: TextStyle(fontSize: 13, color: wise.textSecondary)),
                  trailing: Icon(Icons.open_in_new, color: wise.textTertiary, size: 18),
                  onTap: () => _launchUrl('/legal/privacy'),
                ),
                Divider(height: 1, color: wise.border),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.xs),
                  title: Text(l10n.termsOfService, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: wise.textPrimary)),
                  subtitle: Text(l10n.viewTermsOfService, style: TextStyle(fontSize: 13, color: wise.textSecondary)),
                  trailing: Icon(Icons.open_in_new, color: wise.textTertiary, size: 18),
                  onTap: () => _launchUrl('/legal/terms'),
                ),
              ],
            ),
          ),
          SizedBox(height: wise.spacing.xxl),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: wise.spacing.lg),
            child: Text(
              l10n.versionInfo(_version),
              style: TextStyle(fontSize: 13, color: wise.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
