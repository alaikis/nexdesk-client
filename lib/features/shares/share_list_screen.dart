import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'share_provider.dart';
import '../../features/devices/device_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ShareListScreen extends StatefulWidget {
  const ShareListScreen({super.key});

  @override
  State<ShareListScreen> createState() => _ShareListScreenState();
}

class _ShareListScreenState extends State<ShareListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShareProvider>().loadShares();
    });
  }

  Future<void> _createShare() async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    int? selectedDeviceId;
    final devices = context.read<DeviceProvider>().devices;
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final wise = WiseTheme.of(context);
          final primaryColor = wise.primary;
          final textPrimary = wise.textPrimary;
          final textSecondary = wise.textSecondary;
          final cardColor = wise.card;

          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(wise.radius.lg),
            ),
            title: Text(
              l10n.createShare,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: l10n.shareName,
                    labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.localPath,
                    labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l10n.deviceLabel,
                    labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  items: devices.map((d) {
                    return DropdownMenuItem(value: int.tryParse(d.id), child: Text(d.name));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedDeviceId = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: textSecondary, fontSize: 15, fontWeight: FontWeight.w400),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: wise.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(wise.radius.medium),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.create, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final ok = await context.read<ShareProvider>().createShare(
        nameController.text,
        pathController.text,
        selectedDeviceId ?? 0,
        false,
      );
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shareCreated)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shares = context.watch<ShareProvider>().shares;
    final l10n = AppLocalizations.of(context)!;
    final shareProvider = context.read<ShareProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final backgroundColor = wise.background;
    final cardColor = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final textTertiary = wise.textTertiary;
    final borderColor = wise.border;
    final destructiveColor = wise.error;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.shares,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            height: 1.4,
          ),
        ),
      ),
      body: shares.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: wise.primarySoft,
                      borderRadius: BorderRadius.circular(wise.radius.lg),
                    ),
                    child: Icon(Icons.folder_shared, size: 36, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSharesYet,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textSecondary, height: 1.53),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: wise.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(wise.radius.medium),
                      ),
                    ),
                    onPressed: _createShare,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.createShare, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: shares.length,
              itemBuilder: (context, index) {
                final share = shares[index];
                return _ShareCard(
                  share: share,
                  primaryColor: primaryColor,
                  cardColor: cardColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textTertiary: textTertiary,
                  borderColor: borderColor,
                  destructiveColor: destructiveColor,
                  onTap: () {
                    context.read<ShareProvider>().browseShare(share.id, '/');
                    context.push('/shares/${share.id}');
                  },
                  onDelete: () async {
                    final ok = await shareProvider.deleteShare(share.id);
                    if (mounted && ok) {
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.shareDeleted)));
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: wise.onPrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(wise.radius.lg),
        ),
        onPressed: _createShare,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShareCard extends StatefulWidget {
  final Share share;
  final Color primaryColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderColor;
  final Color destructiveColor;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _ShareCard({
    required this.share,
    required this.primaryColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.destructiveColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final wise = WiseTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(wise.radius.lg),
            border: Border.all(color: widget.borderColor),
            boxShadow: _hovering ? wise.shadows.md : wise.shadows.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: wise.primaryTint,
                  borderRadius: BorderRadius.circular(wise.radius.medium),
                ),
                child: Icon(Icons.folder, size: 20, color: widget.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.share.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                        height: 1.53,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.share.path,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: Icon(Icons.delete_outline, size: 20),
                color: widget.textTertiary,
                style: IconButton.styleFrom(
                  foregroundColor: widget.destructiveColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(wise.radius.sm),
                  ),
                ),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
