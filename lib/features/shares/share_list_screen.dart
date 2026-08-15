import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'share_provider.dart';
import '../../features/devices/device_provider.dart';
import '../../l10n/app_localizations.dart';

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
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.createShare),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.shareName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pathController,
                decoration: InputDecoration(labelText: l10n.localPath),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: l10n.deviceLabel),
                items: devices.map((d) {
                  return DropdownMenuItem(value: int.tryParse(d.id), child: Text(d.name));
                }).toList(),
                onChanged: (value) => setDialogState(() => selectedDeviceId = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.create),
            ),
          ],
        ),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shares)),
      body: shares.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_shared, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l10n.noSharesYet, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _createShare, icon: const Icon(Icons.add), label: Text(l10n.createShare)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shares.length,
              itemBuilder: (context, index) {
                final share = shares[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                    title: Text(share.name),
                    subtitle: Text(share.path),
                    trailing: IconButton(
                      onPressed: () async {
                        final ok = await context.read<ShareProvider>().deleteShare(share.id);
                        if (mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shareDeleted)));
                        }
                      },
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () {
                      context.read<ShareProvider>().browseShare(share.id, '/');
                      context.push('/shares/${share.id}');
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createShare,
        child: const Icon(Icons.add),
      ),
    );
  }
}
