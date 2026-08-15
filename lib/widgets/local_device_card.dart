import 'package:flutter/material.dart';
import '../features/devices/device_provider.dart';
import 'nex_card.dart';
import 'online_dot.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LocalDeviceCard extends StatelessWidget {
  final Device device;
  final ValueChanged<String> onCopy;

  const LocalDeviceCard({super.key, required this.device, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return NexCard(
      color: cs.primaryContainer.withValues(alpha: 0.15),
      padding: EdgeInsets.all(NexSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.computer, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.thisDevice, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deviceCodeLabel, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: device.code.isEmpty ? null : () => onCopy(device.code),
                      child: Row(
                        children: [
                          Text(
                            device.code.isEmpty ? l10n.notSet : device.code,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: cs.primary),
                          ),
                          if (device.code.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.controlPasswordLabel, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      device.hasControlPassword ? '••••••••' : l10n.notSet,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OnlineDot(isOnline: device.online),
              const SizedBox(width: 8),
              Text(device.name, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
