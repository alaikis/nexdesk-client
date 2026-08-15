import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> device;

  const SecuritySettingsScreen({
    super.key,
    required this.deviceId,
    required this.device,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final ApiClient _api = ApiClient();
  bool _saving = false;
  bool _hasLockPassword = false;
  String _allowedUsers = '';
  String _blockedUsers = '';
  final TextEditingController _lockPasswordController = TextEditingController();
  final TextEditingController _allowedController = TextEditingController();
  final TextEditingController _blockedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hasLockPassword = widget.device['has_lock_password'] == true;
    _allowedUsers = widget.device['allowed_users'] ?? '';
    _blockedUsers = widget.device['blocked_users'] ?? '';
  }

  Future<void> _setLockPassword() async {
    final password = _lockPasswordController.text.trim();
    if (password.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _api.setLockPassword(widget.deviceId, password);
      setState(() => _hasLockPassword = true);
      _lockPasswordController.clear();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lockPasswordSet)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failed(e.message))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeLockPassword() async {
    setState(() => _saving = true);
    try {
      await _api.removeLockPassword(widget.deviceId);
      setState(() => _hasLockPassword = false);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lockPasswordRemoved)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failed(e.message))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAllowedUsers() async {
    final raw = _allowedController.text.trim();
    final ids = raw.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
    setState(() => _saving = true);
    try {
      await _api.setAllowedUsers(widget.deviceId, ids);
      setState(() => _allowedUsers = raw);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allowedUsersUpdated)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failed(e.message))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveBlockedUsers() async {
    final raw = _blockedController.text.trim();
    final ids = raw.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
    setState(() => _saving = true);
    try {
      await _api.setBlockedUsers(widget.deviceId, ids);
      setState(() => _blockedUsers = raw);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.blockedUsersUpdated)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failed(e.message))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.securitySettings)),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(l10n.connectionSecurity, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 20),
                _buildLockCard(cs),
                const SizedBox(height: 16),
                _buildAllowedCard(cs),
                const SizedBox(height: 16),
                _buildBlockedCard(cs),
                const SizedBox(height: 16),
                _buildInfoCard(cs),
              ],
            ),
    );
  }

  Widget _buildLockCard(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: _hasLockPassword ? const Color(0xFF34C759) : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hasLockPassword ? l10n.lockPasswordEnabled : l10n.lockPasswordDisabled,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_hasLockPassword) ...[
              TextField(
                controller: _lockPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.newLockPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _setLockPassword,
                icon: const Icon(Icons.lock_open),
                label: Text(l10n.setLockPassword),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _removeLockPassword,
                icon: const Icon(Icons.lock_open),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                ),
                label: Text(l10n.removeLockPassword),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllowedCard(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: const Color(0xFF34C759)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.allowedUsers, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allowedController,
              decoration: InputDecoration(
                labelText: l10n.allowedUserIds,
                hintText: _allowedUsers.isEmpty ? l10n.allowedUsersExample : _allowedUsers,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveAllowedUsers,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveAllowedUsers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedCard(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: const Color(0xFFFF3B30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.blockedUsers, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _blockedController,
              decoration: InputDecoration(
                labelText: l10n.blockedUserIds,
                hintText: _blockedUsers.isEmpty ? l10n.blockedUsersExample : _blockedUsers,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveBlockedUsers,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveBlockedUsers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.connectionPermissions, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.lockPasswordInfo),
            const SizedBox(height: 8),
            Text(l10n.allowedUsersInfo),
            const SizedBox(height: 8),
            Text(l10n.blockedUsersInfo),
          ],
        ),
      ),
    );
  }
}
