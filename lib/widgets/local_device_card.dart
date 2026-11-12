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
    final wise = WiseTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final primaryColor = wise.primary;
    final cardBackground = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final textTertiary = wise.textTertiary;

    return NexCard(
      color: cardBackground,
      enableShadow: true,
      padding: EdgeInsets.all(wise.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.computer, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(l10n.thisDevice, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          SizedBox(height: wise.spacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deviceCodeLabel, style: TextStyle(fontSize: 13, color: textSecondary)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: device.code.isEmpty ? null : () => onCopy(device.code),
                      child: Row(
                        children: [
                          Text(
                            device.code.isEmpty ? l10n.notSet : device.code,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: WiseTypographyTokens.monoFamily, color: primaryColor),
                          ),
                          if (device.code.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.copy, size: 14, color: textTertiary),
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
                    Text(l10n.controlPasswordLabel, style: TextStyle(fontSize: 13, color: textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      device.hasControlPassword ? '••••••••' : l10n.notSet,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: wise.spacing.sm),
          Row(
            children: [
              OnlineDot(isOnline: device.online),
              const SizedBox(width: 8),
              Text(device.name, style: TextStyle(fontSize: 13, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
