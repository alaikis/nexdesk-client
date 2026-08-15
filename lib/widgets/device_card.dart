import 'package:flutter/material.dart';
import '../features/devices/device_provider.dart';
import 'nex_card.dart';
import 'online_dot.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onCopy;
  final VoidCallback? onWake;
  final String? wakingDeviceId;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onCopy,
    this.onWake,
    this.wakingDeviceId,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = NexCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: isSelected ? cs.primary : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.computer, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(device.os, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (device.code.isNotEmpty) ...[
            GestureDetector(
              onTap: onCopy,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  device.code,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
          OnlineDot(isOnline: device.online),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: onConnect,
            child: const Text('Connect'),
          ),
          if (onWake != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: wakingDeviceId == device.id ? null : onWake,
              tooltip: 'Wake',
              icon: wakingDeviceId == device.id
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.power_settings_new, size: 18, color: cs.primary),
            ),
          ],
        ],
      ),
    );
    if (onTap != null && onLongPress != null) {
      return GestureDetector(onTap: onTap, onLongPress: onLongPress, child: card);
    }
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    if (onLongPress != null) {
      return GestureDetector(onLongPress: onLongPress, child: card);
    }
    return card;
  }
}
