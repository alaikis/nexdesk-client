import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'two_factor_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _baseUrl = 'https://nex.hottol.com';

  Future<void> _launchUrl(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开链接: $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Manage 2FA settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TwoFactorScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View privacy policy'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl('/legal/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Terms of Service'),
                  subtitle: const Text('View terms of service'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl('/legal/terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'NEX version 0.1.0',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
          ),
        ],
      ),
    );
  }
}
