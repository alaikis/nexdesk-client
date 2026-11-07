import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/nex_button.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final successColor = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.securitySettings)),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.connectionSecurity,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 20),
                _buildLockCard(isDark, primaryColor, textPrimary, textSecondary, successColor, errorColor),
                const SizedBox(height: 16),
                _buildAllowedCard(isDark, primaryColor, textPrimary, textSecondary, successColor),
                const SizedBox(height: 16),
                _buildBlockedCard(isDark, primaryColor, textPrimary, textSecondary, errorColor),
                const SizedBox(height: 16),
                _buildInfoCard(isDark, primaryColor, textPrimary, textSecondary),
              ],
            ),
    );
  }

  Widget _buildSectionIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(NexRadius.md),
      ),
      child: Icon(icon, color: color, size: 22),
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

  Widget _buildLockCard(bool isDark, Color primaryColor, Color textPrimary, Color textSecondary, Color successColor, Color errorColor) {
    final l10n = AppLocalizations.of(context)!;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return NexCard(
      color: cardColor,
      enableShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIcon(Icons.shield_outlined, _hasLockPassword ? successColor : primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lockPasswordDisabled.replaceAll('Disabled', '').replaceAll('Enabled', '').trim().isEmpty
                          ? (_hasLockPassword ? l10n.lockPasswordEnabled : l10n.lockPasswordDisabled)
                          : (_hasLockPassword ? l10n.lockPasswordEnabled : l10n.lockPasswordDisabled),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    _buildStatusBadge(
                      _hasLockPassword ? 'Enabled' : 'Disabled',
                      isSuccess: _hasLockPassword,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_hasLockPassword) ...[
            TextField(
              controller: _lockPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newLockPassword,
              ),
            ),
            const SizedBox(height: 12),
            NexButton(
              text: l10n.setLockPassword,
              icon: const Icon(Icons.lock_open, size: 18),
              onPressed: _setLockPassword,
            ),
          ] else ...[
            NexButton(
              text: l10n.removeLockPassword,
              icon: const Icon(Icons.lock_open, size: 18),
              variant: NexButtonVariant.destructive,
              onPressed: _removeLockPassword,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllowedCard(bool isDark, Color primaryColor, Color textPrimary, Color textSecondary, Color successColor) {
    final l10n = AppLocalizations.of(context)!;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return NexCard(
      color: cardColor,
      enableShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIcon(Icons.check_circle_outline, successColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.allowedUsers,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _allowedController,
            decoration: InputDecoration(
              labelText: l10n.allowedUserIds,
              hintText: _allowedUsers.isEmpty ? l10n.allowedUsersExample : _allowedUsers,
            ),
          ),
          const SizedBox(height: 12),
          NexButton(
            text: l10n.saveAllowedUsers,
            icon: const Icon(Icons.save, size: 18),
            onPressed: _saveAllowedUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedCard(bool isDark, Color primaryColor, Color textPrimary, Color textSecondary, Color errorColor) {
    final l10n = AppLocalizations.of(context)!;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return NexCard(
      color: cardColor,
      enableShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIcon(Icons.block, errorColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.blockedUsers,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _blockedController,
            decoration: InputDecoration(
              labelText: l10n.blockedUserIds,
              hintText: _blockedUsers.isEmpty ? l10n.blockedUsersExample : _blockedUsers,
            ),
          ),
          const SizedBox(height: 12),
          NexButton(
            text: l10n.saveBlockedUsers,
            icon: const Icon(Icons.save, size: 18),
            onPressed: _saveBlockedUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, Color primaryColor, Color textPrimary, Color textSecondary) {
    final l10n = AppLocalizations.of(context)!;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    return NexCard(
      color: cardColor,
      enableShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIcon(Icons.info_outline, primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.connectionPermissions,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.lockPasswordInfo, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
          const SizedBox(height: 8),
          Text(l10n.allowedUsersInfo, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
          const SizedBox(height: 8),
          Text(l10n.blockedUsersInfo, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
