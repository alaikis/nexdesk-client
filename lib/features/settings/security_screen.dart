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
    final wise = WiseTheme.of(context);

    return Scaffold(
      backgroundColor: wise.background,
      appBar: AppBar(title: Text(l10n.securitySettings)),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(wise.spacing.xl),
              children: [
                Text(
                  l10n.connectionSecurity,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: wise.textPrimary, height: 1.4),
                ),
                SizedBox(height: wise.spacing.xl),
                _buildLockCard(wise),
                SizedBox(height: wise.spacing.lg),
                _buildAllowedCard(wise),
                SizedBox(height: wise.spacing.lg),
                _buildBlockedCard(wise),
                SizedBox(height: wise.spacing.lg),
                _buildInfoCard(wise),
              ],
            ),
    );
  }

  Widget _buildSectionIcon(IconData icon, Color color) {
    final wise = WiseTheme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(wise.radius.medium),
      ),
      child: Icon(icon, color: color, size: 22),
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

  Widget _buildLockCard(WiseTheme wise) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = wise.textPrimary;
    final successColor = wise.success;
    final primaryColor = wise.primary;
    return NexCard(
      color: wise.card,
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53),
                    ),
                    const SizedBox(height: 2),
                    _buildStatusBadge(
                      _hasLockPassword ? 'Enabled' : 'Disabled',
                      isSuccess: _hasLockPassword,
                      context: context,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: wise.spacing.lg),
          if (!_hasLockPassword) ...[
            TextField(
              controller: _lockPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newLockPassword,
              ),
            ),
            SizedBox(height: wise.spacing.md),
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

  Widget _buildAllowedCard(WiseTheme wise) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = wise.textPrimary;
    final successColor = wise.success;
    return NexCard(
      color: wise.card,
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53),
                ),
              ),
            ],
          ),
          SizedBox(height: wise.spacing.lg),
          TextField(
            controller: _allowedController,
            decoration: InputDecoration(
              labelText: l10n.allowedUserIds,
              hintText: _allowedUsers.isEmpty ? l10n.allowedUsersExample : _allowedUsers,
            ),
          ),
          SizedBox(height: wise.spacing.md),
          NexButton(
            text: l10n.saveAllowedUsers,
            icon: const Icon(Icons.save, size: 18),
            onPressed: _saveAllowedUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedCard(WiseTheme wise) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = wise.textPrimary;
    final errorColor = wise.error;
    return NexCard(
      color: wise.card,
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53),
                ),
              ),
            ],
          ),
          SizedBox(height: wise.spacing.lg),
          TextField(
            controller: _blockedController,
            decoration: InputDecoration(
              labelText: l10n.blockedUserIds,
              hintText: _blockedUsers.isEmpty ? l10n.blockedUsersExample : _blockedUsers,
            ),
          ),
          SizedBox(height: wise.spacing.md),
          NexButton(
            text: l10n.saveBlockedUsers,
            icon: const Icon(Icons.save, size: 18),
            onPressed: _saveBlockedUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(WiseTheme wise) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final primaryColor = wise.primary;
    return NexCard(
      color: wise.card,
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.53),
                ),
              ),
            ],
          ),
          SizedBox(height: wise.spacing.md),
          Text(l10n.lockPasswordInfo, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.54)),
          SizedBox(height: wise.spacing.sm),
          Text(l10n.allowedUsersInfo, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.54)),
          SizedBox(height: wise.spacing.sm),
          Text(l10n.blockedUsersInfo, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.54)),
        ],
      ),
    );
  }
}
