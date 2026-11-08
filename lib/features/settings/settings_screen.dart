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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7);
    final cardBackground = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);
    final textTertiary = isDark ? const Color(0xFF78716C) : const Color(0xFF9C958D);
    final dividerColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE);

    return Container(
      color: backgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.settings, 
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.w700, 
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          NexCard(
            color: cardBackground,
            enableShadow: true,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(l10n.security, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                  subtitle: Text(l10n.manageSecuritySettings, style: TextStyle(fontSize: 13, color: textSecondary)),
                  trailing: Icon(Icons.chevron_right, color: textTertiary),
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
                Divider(height: 1, color: dividerColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(l10n.twoFactorAuth, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                  subtitle: Text(l10n.manage2FASettings, style: TextStyle(fontSize: 13, color: textSecondary)),
                  trailing: Icon(Icons.chevron_right, color: textTertiary),
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
            color: cardBackground,
            enableShadow: true,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(l10n.language, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                  subtitle: Text(l10n.selectLanguage, style: TextStyle(fontSize: 13, color: textSecondary)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _changeLanguage(value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'en', child: Text(l10n.english)),
                      PopupMenuItem(value: 'zh', child: Text(l10n.chinese)),
                    ],
                    child: const Icon(Icons.language),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NexCard(
            color: cardBackground,
            enableShadow: true,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(l10n.privacyPolicy, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                  subtitle: Text(l10n.viewPrivacyPolicy, style: TextStyle(fontSize: 13, color: textSecondary)),
                  trailing: Icon(Icons.open_in_new, color: textTertiary),
                  onTap: () => _launchUrl('/legal/privacy'),
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(l10n.termsOfService, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                  subtitle: Text(l10n.viewTermsOfService, style: TextStyle(fontSize: 13, color: textSecondary)),
                  trailing: Icon(Icons.open_in_new, color: textTertiary),
                  onTap: () => _launchUrl('/legal/terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.versionInfo(_version), 
              style: TextStyle(fontSize: 13, color: textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
