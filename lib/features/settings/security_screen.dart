import 'package:flutter/material.dart';
import '../../core/api_client.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lock password set')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lock password removed')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowed users updated')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocked users updated')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Connection Security', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
                    _hasLockPassword ? 'Lock password enabled' : 'Lock password disabled',
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
                decoration: const InputDecoration(
                  labelText: 'New lock password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _setLockPassword,
                icon: const Icon(Icons.lock_open),
                label: const Text('Set Lock Password'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _removeLockPassword,
                icon: const Icon(Icons.lock_open),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                ),
                label: const Text('Remove Lock Password'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllowedCard(ColorScheme cs) {
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
                const Expanded(
                  child: Text('Allowed Users', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allowedController,
              decoration: InputDecoration(
                labelText: 'Allowed user IDs (comma separated)',
                hintText: _allowedUsers.isEmpty ? 'e.g. 1, 2, 3' : _allowedUsers,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveAllowedUsers,
              icon: const Icon(Icons.save),
              label: const Text('Save Allowed Users'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedCard(ColorScheme cs) {
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
                const Expanded(
                  child: Text('Blocked Users', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _blockedController,
              decoration: InputDecoration(
                labelText: 'Blocked user IDs (comma separated)',
                hintText: _blockedUsers.isEmpty ? 'e.g. 4, 5' : _blockedUsers,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveBlockedUsers,
              icon: const Icon(Icons.save),
              label: const Text('Save Blocked Users'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs) {
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
                const Expanded(
                  child: Text('Connection Permissions', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('When a lock password is set, remote connections must provide the password.'),
            const SizedBox(height: 8),
            const Text('Allowed users restrict connections to only the specified users.'),
            const SizedBox(height: 8),
            const Text('Blocked users prevent specific users from connecting.'),
          ],
        ),
      ),
    );
  }
}
